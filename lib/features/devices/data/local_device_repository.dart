import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/device.dart';
import '../domain/device_repository.dart';

/// Guarda los dispositivos como JSON en SharedPreferences.
/// Para una BD real (SQLite/Drift/Isar) o una API, crea otra clase que
/// implemente DeviceRepository y cambia el provider.
class LocalDeviceRepository implements DeviceRepository {
  static const _key = 'devices_v2';

  final SharedPreferences _prefs;
  LocalDeviceRepository(this._prefs);

  // Coordenadas de ejemplo (centro de CDMX). Cámbialas a tu zona.
  static const _seed = [
    Device(
      id: '1',
      name: 'Sensor temperatura A1',
      location: 'Planta 1',
      type: DeviceType.sensor,
      status: DeviceStatus.online,
      threshold: 80,
      latitude: 19.4350,
      longitude: -99.1410,
    ),
    Device(
      id: '2',
      name: 'Gateway principal',
      location: 'Cuarto de control',
      type: DeviceType.gateway,
      status: DeviceStatus.online,
      threshold: 90,
      latitude: 19.4290,
      longitude: -99.1350,
    ),
    Device(
      id: '3',
      name: 'Sensor humedad B2',
      location: 'Bodega',
      type: DeviceType.sensor,
      status: DeviceStatus.warning,
      threshold: 70,
      latitude: 19.4400,
      longitude: -99.1280,
    ),
    Device(
      id: '4',
      name: 'Controlador bomba 1',
      location: 'Planta 2',
      type: DeviceType.controller,
      status: DeviceStatus.offline,
      threshold: 60,
      latitude: 19.4250,
      longitude: -99.1250,
    ),
  ];

  Future<List<Device>> _load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      await _save(_seed);
      return List.of(_seed);
    }
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Device.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(List<Device> devices) => _prefs.setString(
        _key,
        jsonEncode(devices.map((d) => d.toJson()).toList()),
      );

  @override
  Future<List<Device>> getAll() => _load();

  @override
  Future<void> upsert(Device device) async {
    final list = await _load();
    final i = list.indexWhere((d) => d.id == device.id);
    if (i >= 0) {
      list[i] = device;
    } else {
      list.add(device);
    }
    await _save(list);
  }

  @override
  Future<void> delete(String id) async {
    final list = await _load();
    list.removeWhere((d) => d.id == id);
    await _save(list);
  }
}
