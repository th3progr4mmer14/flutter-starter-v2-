import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/local_geofence_repository.dart';
import '../../domain/geofence.dart';

final geofenceRepositoryProvider = Provider<LocalGeofenceRepository>(
  (ref) => LocalGeofenceRepository(ref.watch(sharedPreferencesProvider)),
);

class GeofencesController extends AsyncNotifier<List<Geofence>> {
  LocalGeofenceRepository get _repo => ref.read(geofenceRepositoryProvider);

  @override
  Future<List<Geofence>> build() => _repo.getAll();

  Future<void> save(Geofence geofence) async {
    final list = [...(state.value ?? await future)];
    final i = list.indexWhere((g) => g.id == geofence.id);
    if (i >= 0) {
      list[i] = geofence;
    } else {
      list.add(geofence);
    }
    state = AsyncData(list);
    await _repo.saveAll(list);
  }

  Future<void> delete(String id) async {
    // Actualización inmediata (necesaria para Dismissible) y luego persiste.
    final list = (state.value ?? <Geofence>[]).where((g) => g.id != id).toList();
    state = AsyncData(list);
    await _repo.saveAll(list);
  }
}

final geofencesControllerProvider =
    AsyncNotifierProvider<GeofencesController, List<Geofence>>(
        GeofencesController.new);
