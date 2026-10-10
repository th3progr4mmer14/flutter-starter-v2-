import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/local_device_repository.dart';
import '../../domain/device.dart';
import '../../domain/device_repository.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => LocalDeviceRepository(ref.watch(sharedPreferencesProvider)),
);

class DevicesController extends AsyncNotifier<List<Device>> {
  DeviceRepository get _repo => ref.read(deviceRepositoryProvider);

  @override
  Future<List<Device>> build() => _repo.getAll();

  Future<void> save(Device device) async {
    await _repo.upsert(device);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> delete(String id) async {
    // Actualiza la UI al instante (necesario para Dismissible) y luego persiste.
    final current = state.value ?? <Device>[];
    state = AsyncData(current.where((d) => d.id != id).toList());
    await _repo.delete(id);
  }
}

final devicesControllerProvider =
    AsyncNotifierProvider<DevicesController, List<Device>>(
        DevicesController.new);
