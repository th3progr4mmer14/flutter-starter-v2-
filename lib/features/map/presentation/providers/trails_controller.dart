import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../authentication/presentation/providers/auth_controller.dart';
import 'live_locations_provider.dart';

/// Historial de recorrido por dispositivo: guarda las últimas posiciones que
/// emite liveLocationsProvider (en memoria; se pierde al cerrar la app).
/// Para historial persistente/consultable por fechas, reemplaza esto por una
/// consulta a tu backend o a una base local (SQLite/Drift).
class TrailsController extends Notifier<Map<String, List<LatLng>>> {
  static const maxPoints = 100;

  @override
  Map<String, List<LatLng>> build() {
    final authed = ref.watch(
        authControllerProvider.select((s) => s.status == AuthStatus.authenticated));
    if (!authed) return {};

    ref.listen<AsyncValue<Map<String, LatLng>>>(liveLocationsProvider,
        (_, next) {
      final positions = next.value;
      if (positions == null) return;

      final updated = {...state};
      positions.forEach((id, point) {
        final list = [...(updated[id] ?? const <LatLng>[])];
        if (list.isEmpty || list.last != point) list.add(point);
        if (list.length > maxPoints) {
          list.removeRange(0, list.length - maxPoints);
        }
        updated[id] = list;
      });
      state = updated;
    });

    return {};
  }

  void clear() => state = {};
}

final trailsControllerProvider =
    NotifierProvider<TrailsController, Map<String, List<LatLng>>>(
        TrailsController.new);
