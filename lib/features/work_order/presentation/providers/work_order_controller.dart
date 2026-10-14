import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/local_work_order_repository.dart';
import '../../domain/work_order_item.dart';
import '../../domain/work_order_repository.dart';

final workOrderRepositoryProvider = Provider<WorkOrderRepository>(
  (ref) => LocalWorkOrderRepository(ref.watch(sharedPreferencesProvider)),
);

class WorkOrderController extends AsyncNotifier<List<WorkOrderItem>> {
  WorkOrderRepository get _repo => ref.read(workOrderRepositoryProvider);

  @override
  Future<List<WorkOrderItem>> build() => _repo.getAll();

  Future<void> save(WorkOrderItem item) async {
    await _repo.upsert(item);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> delete(String id) async {
    // Actualiza la UI al instante (necesario para Dismissible) y luego persiste.
    final current = state.value ?? <WorkOrderItem>[];
    state = AsyncData(current.where((i) => i.id != id).toList());
    await _repo.delete(id);
  }
}

final workOrderControllerProvider =
    AsyncNotifierProvider<WorkOrderController, List<WorkOrderItem>>(
        WorkOrderController.new);
