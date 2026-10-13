import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/geofence.dart';

/// Geocercas guardadas en el dispositivo. Para un backend, conviértela en
/// interfaz (como DeviceRepository) y crea la implementación remota.
class LocalGeofenceRepository {
  static const _key = 'geofences_v1';

  final SharedPreferences _prefs;
  LocalGeofenceRepository(this._prefs);

  // Geocerca de ejemplo alrededor de los dispositivos de demo (CDMX).
  static const _seed = [
    Geofence(
      id: 'g1',
      name: 'Zona planta',
      latitude: 19.4330,
      longitude: -99.1340,
      radiusMeters: 800,
      trigger: GeofenceTrigger.exit,
    ),
  ];

  Future<List<Geofence>> getAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      await saveAll(_seed);
      return List.of(_seed);
    }
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Geofence.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveAll(List<Geofence> geofences) => _prefs.setString(
        _key,
        jsonEncode(geofences.map((g) => g.toJson()).toList()),
      );
}
