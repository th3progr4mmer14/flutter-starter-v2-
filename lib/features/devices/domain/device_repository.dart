import 'device.dart';

abstract class DeviceRepository {
  Future<List<Device>> getAll();
  Future<void> upsert(Device device);
  Future<void> delete(String id);
}
