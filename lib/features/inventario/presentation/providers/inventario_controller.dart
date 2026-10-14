import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/local_inventario_repository.dart';
import '../../domain/inventario_item.dart';
import '../../domain/inventario_repository.dart';

final inventarioRepositoryProvider = Provider<InventarioRepository>(
  (ref) => LocalInventarioRepository(ref.watch(sharedPreferencesProvider)),
);

class InventarioController extends AsyncNotifier<List<InventarioItem>> {
  InventarioRepository get _repo => ref.read(inventarioRepositoryProvider);

  @override
  Future<List<InventarioItem>> build() => _repo.getAll();

  Future<void> save(InventarioItem item) async {
    await _repo.upsert(item);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> delete(String id) async {
    // Actualiza la UI al instante (necesario para Dismissible) y luego persiste.
    final current = state.value ?? <InventarioItem>[];
    state = AsyncData(current.where((i) => i.id != id).toList());
    await _repo.delete(id);
  }
}

final inventarioControllerProvider =
    AsyncNotifierProvider<InventarioController, List<InventarioItem>>(
        InventarioController.new);
