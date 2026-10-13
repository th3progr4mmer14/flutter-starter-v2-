enum GeofenceTrigger { exit, enter }

class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceTrigger trigger;

  /// null = aplica a todos los dispositivos.
  final String? deviceId;

  const Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.trigger = GeofenceTrigger.exit,
    this.deviceId,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        trigger: GeofenceTrigger.values.firstWhere(
          (e) => e.name == json['trigger'],
          orElse: () => GeofenceTrigger.exit,
        ),
        deviceId: json['deviceId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'trigger': trigger.name,
        'deviceId': deviceId,
      };
}
