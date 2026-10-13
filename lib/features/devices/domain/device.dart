enum DeviceStatus { online, offline, warning }

enum DeviceType { sensor, gateway, controller }

class Device {
  final String id;
  final String name;
  final String location;
  final DeviceType type;
  final DeviceStatus status;
  final double threshold;

  /// Coordenadas opcionales (para la sección de mapa).
  final double? latitude;
  final double? longitude;

  const Device({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.status,
    required this.threshold,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Device copyWith({
    String? name,
    String? location,
    DeviceType? type,
    DeviceStatus? status,
    double? threshold,
    double? latitude,
    double? longitude,
  }) {
    return Device(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      threshold: threshold ?? this.threshold,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String? ?? '',
        type: DeviceType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DeviceType.sensor,
        ),
        status: DeviceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DeviceStatus.offline,
        ),
        threshold: (json['threshold'] as num?)?.toDouble() ?? 80,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'type': type.name,
        'status': status.name,
        'threshold': threshold,
        'latitude': latitude,
        'longitude': longitude,
      };
}
