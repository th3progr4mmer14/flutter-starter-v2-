enum AlertSeverity { info, warning, critical }

class AlertItem {
  final String id;
  final String title;
  final String deviceName;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool acknowledged;

  const AlertItem({
    required this.id,
    required this.title,
    required this.deviceName,
    required this.severity,
    required this.timestamp,
    this.acknowledged = false,
  });

  AlertItem copyWith({bool? acknowledged}) => AlertItem(
        id: id,
        title: title,
        deviceName: deviceName,
        severity: severity,
        timestamp: timestamp,
        acknowledged: acknowledged ?? this.acknowledged,
      );

  factory AlertItem.fromJson(Map<String, dynamic> json) => AlertItem(
        id: json['id'] as String,
        title: json['title'] as String,
        deviceName: json['deviceName'] as String? ?? '',
        severity: AlertSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => AlertSeverity.info,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        acknowledged: json['acknowledged'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'deviceName': deviceName,
        'severity': severity.name,
        'timestamp': timestamp.toIso8601String(),
        'acknowledged': acknowledged,
      };
}
