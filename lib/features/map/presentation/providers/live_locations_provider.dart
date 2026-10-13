import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../../../settings/presentation/providers/settings_controller.dart';

/// Posiciones SIMULADAS: parten de las coordenadas guardadas en cada
/// dispositivo y se mueven un poco cada intervalo (los "offline" no se mueven).
///
/// Cuando tengas datos reales (MQTT, WebSocket, REST con polling...) reemplaza
/// el cuerpo de este provider para que emita `Map<idDispositivo, LatLng>`;
/// la pantalla de mapa no cambia.
final liveLocationsProvider =
    StreamProvider.autoDispose<Map<String, LatLng>>((ref) async* {
  final seconds =
      ref.watch(settingsControllerProvider.select((s) => s.refreshSeconds));
  final devices = (ref.watch(devicesControllerProvider).value ?? <Device>[])
      .where((d) => d.hasLocation)
      .toList();

  final rnd = Random();
  final positions = <String, LatLng>{
    for (final d in devices) d.id: LatLng(d.latitude!, d.longitude!),
  };
  yield Map.of(positions);

  while (true) {
    await Future.delayed(Duration(seconds: seconds));
    for (final d in devices) {
      if (d.status == DeviceStatus.offline) continue;
      final p = positions[d.id]!;
      positions[d.id] = LatLng(
        p.latitude + (rnd.nextDouble() - 0.5) * 0.0006,
        p.longitude + (rnd.nextDouble() - 0.5) * 0.0006,
      );
    }
    yield Map.of(positions);
  }
});
