import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_controller.dart';

/// Lecturas SIMULADAS. Cuando tengas datos reales (MQTT, WebSocket, REST con
/// polling...) reemplaza el cuerpo de este provider; la UI no cambia.
final liveMetricsProvider = StreamProvider.autoDispose<List<double>>((ref) async* {
  final seconds =
      ref.watch(settingsControllerProvider.select((s) => s.refreshSeconds));

  final rnd = Random();
  double next(double v) =>
      (v + (rnd.nextDouble() - 0.5) * 12).clamp(10.0, 95.0).toDouble();

  var value = 55.0;
  final points = <double>[];
  for (var i = 0; i < 20; i++) {
    value = next(value);
    points.add(value);
  }
  yield List.of(points);

  while (true) {
    await Future.delayed(Duration(seconds: seconds));
    value = next(value);
    points.add(value);
    if (points.length > 30) points.removeAt(0);
    yield List.of(points);
  }
});
