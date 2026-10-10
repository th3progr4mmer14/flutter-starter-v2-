import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/alert_item.dart';

/// Alertas de demo guardadas localmente. Cuando tengas un backend / MQTT,
/// reemplaza esta clase (o conviértela en interfaz como DeviceRepository).
class LocalAlertRepository {
  static const _key = 'alerts_v1';

  final SharedPreferences _prefs;
  LocalAlertRepository(this._prefs);

  List<AlertItem> _seed() {
    final now = DateTime.now();
    return [
      AlertItem(
        id: 'a1',
        title: 'Temperatura sobre el umbral',
        deviceName: 'Sensor temperatura A1',
        severity: AlertSeverity.critical,
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      AlertItem(
        id: 'a2',
        title: 'Humedad alta',
        deviceName: 'Sensor humedad B2',
        severity: AlertSeverity.warning,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      AlertItem(
        id: 'a3',
        title: 'Conexión perdida',
        deviceName: 'Controlador bomba 1',
        severity: AlertSeverity.critical,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      AlertItem(
        id: 'a4',
        title: 'Firmware actualizado',
        deviceName: 'Gateway principal',
        severity: AlertSeverity.info,
        timestamp: now.subtract(const Duration(days: 1)),
        acknowledged: true,
      ),
    ];
  }

  Future<List<AlertItem>> getAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seed = _seed();
      await saveAll(seed);
      return seed;
    }
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AlertItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveAll(List<AlertItem> alerts) => _prefs.setString(
        _key,
        jsonEncode(alerts.map((a) => a.toJson()).toList()),
      );
}
