import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../alerts/domain/alert_item.dart';
import '../../../alerts/presentation/providers/alerts_controller.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../../../settings/presentation/providers/settings_controller.dart';
import '../../domain/geofence.dart';
import 'geofences_controller.dart';
import 'live_locations_provider.dart';

/// Vigila las posiciones y crea una alerta cuando un dispositivo cruza una
/// geocerca (sale o entra, según su configuración).
/// El estado guarda "¿estaba dentro?" por pareja geocerca|dispositivo; la
/// primera lectura nunca dispara alerta, solo los cambios.
class GeofenceMonitor extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final authed = ref.watch(
        authControllerProvider.select((s) => s.status == AuthStatus.authenticated));
    if (!authed) return {};

    ref.listen<AsyncValue<Map<String, LatLng>>>(liveLocationsProvider,
        (_, next) {
      final positions = next.value;
      if (positions != null) _evaluate(positions);
    });

    return {};
  }

  Future<void> _evaluate(Map<String, LatLng> positions) async {
    final fences = ref.read(geofencesControllerProvider).value ?? <Geofence>[];
    final devices = ref.read(devicesControllerProvider).value ?? <Device>[];

    const distance = Distance();
    final previous = state;
    final next = <String, bool>{};
    final events = <(Geofence, Device)>[];

    for (final f in fences) {
      final center = LatLng(f.latitude, f.longitude);
      for (final d in devices) {
        if (f.deviceId != null && f.deviceId != d.id) continue;
        final pos = positions[d.id];
        if (pos == null) continue;

        final inside = distance.distance(center, pos) <= f.radiusMeters;
        final key = '${f.id}|${d.id}';
        next[key] = inside;

        final was = previous[key];
        if (was == null || was == inside) continue;

        if (f.trigger == GeofenceTrigger.exit && was && !inside) {
          events.add((f, d));
        } else if (f.trigger == GeofenceTrigger.enter && !was && inside) {
          events.add((f, d));
        }
      }
    }

    state = next;
    for (final (fence, device) in events) {
      await _raiseAlert(fence, device);
    }
  }

  Future<void> _raiseAlert(Geofence fence, Device device) async {
    // Asegura que las alertas ya estén cargadas antes de agregar una.
    await ref.read(alertsControllerProvider.future);

    // Sin BuildContext: usamos el idioma elegido en Ajustes (o el del sistema).
    final code = ref.read(settingsControllerProvider).languageCode ??
        PlatformDispatcher.instance.locale.languageCode;
    final l = lookupAppLocalizations(Locale(code == 'en' ? 'en' : 'es'));

    final title = fence.trigger == GeofenceTrigger.exit
        ? l.geofenceExitAlert(fence.name)
        : l.geofenceEnterAlert(fence.name);

    await ref.read(alertsControllerProvider.notifier).add(
          AlertItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            deviceName: device.name,
            severity: AlertSeverity.warning,
            timestamp: DateTime.now(),
          ),
        );
  }
}

final geofenceMonitorProvider =
    NotifierProvider<GeofenceMonitor, Map<String, bool>>(GeofenceMonitor.new);
