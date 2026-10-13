import 'package:latlong2/latlong.dart';

/// Ajustes del mapa. Cámbialos por proyecto.
class MapDefaults {
  MapDefaults._();

  /// Centro inicial cuando no hay dispositivos con ubicación.
  static const LatLng center = LatLng(19.4326, -99.1332);
  static const double zoom = 12;

  /// Mosaicos de OpenStreetMap (gratis, sin API key). Ojo: su política de uso
  /// no es para tráfico alto en producción; ahí usa un proveedor de tiles
  /// (MapTiler, Mapbox, Stadia, etc.) o tu propio servidor.
  static const String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Pon aquí el applicationId real de tu app (el de android/app/build.gradle).
  static const String userAgentPackage = 'com.example.flutter_starter_v2';
}
