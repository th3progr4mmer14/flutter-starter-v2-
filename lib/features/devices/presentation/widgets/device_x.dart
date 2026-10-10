import 'package:flutter/material.dart';

import '../../../../l10n/l10n_x.dart';
import '../../domain/device.dart';

extension DeviceStatusX on DeviceStatus {
  String label(AppLocalizations l) => switch (this) {
        DeviceStatus.online => l.statusOnline,
        DeviceStatus.offline => l.statusOffline,
        DeviceStatus.warning => l.statusWarning,
      };

  Color get color => switch (this) {
        DeviceStatus.online => Colors.green,
        DeviceStatus.offline => Colors.grey,
        DeviceStatus.warning => Colors.orange,
      };
}

extension DeviceTypeX on DeviceType {
  String label(AppLocalizations l) => switch (this) {
        DeviceType.sensor => l.typeSensor,
        DeviceType.gateway => l.typeGateway,
        DeviceType.controller => l.typeController,
      };

  IconData get icon => switch (this) {
        DeviceType.sensor => Icons.sensors,
        DeviceType.gateway => Icons.router_outlined,
        DeviceType.controller => Icons.settings_remote_outlined,
      };
}

class StatusChip extends StatelessWidget {
  final DeviceStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            status.label(context.l10n),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
