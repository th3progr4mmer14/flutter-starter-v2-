import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum MyLocationStatus {
  off,
  loading,
  on,
  serviceDisabled,
  denied,
  deniedForever,
}

class MyLocationState {
  final MyLocationStatus status;
  final LatLng? position;

  const MyLocationState({this.status = MyLocationStatus.off, this.position});
}

/// Ubicación del usuario con geolocator. Es autoDispose: al salir del mapa se
/// cancela el GPS (ahorra batería); al volver se activa otra vez.
class MyLocationController extends Notifier<MyLocationState> {
  StreamSubscription<Position>? _sub;

  @override
  MyLocationState build() {
    ref.onDispose(() => _sub?.cancel());
    return const MyLocationState();
  }

  Future<void> toggle() async {
    if (state.status == MyLocationStatus.on ||
        state.status == MyLocationStatus.loading) {
      await _sub?.cancel();
      _sub = null;
      state = const MyLocationState();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    state = const MyLocationState(status: MyLocationStatus.loading);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = const MyLocationState(status: MyLocationStatus.serviceDisabled);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        state = const MyLocationState(status: MyLocationStatus.denied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        state = const MyLocationState(status: MyLocationStatus.deniedForever);
        return;
      }

      await _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // metros mínimos entre actualizaciones
        ),
      ).listen(
        (p) => state = MyLocationState(
          status: MyLocationStatus.on,
          position: LatLng(p.latitude, p.longitude),
        ),
        onError: (_) => state = const MyLocationState(),
      );
    } catch (_) {
      state = const MyLocationState();
    }
  }
}

final myLocationControllerProvider =
    NotifierProvider.autoDispose<MyLocationController, MyLocationState>(
        MyLocationController.new);
