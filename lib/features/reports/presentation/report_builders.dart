import 'package:intl/intl.dart';

import '../../../l10n/l10n_x.dart';
import '../../alerts/domain/alert_item.dart';
import '../../alerts/presentation/widgets/alert_x.dart';
import '../../devices/domain/device.dart';
import '../../devices/presentation/widgets/device_x.dart';
import '../domain/report_table.dart';

/// Para un reporte nuevo: crea otra función que devuelva un ReportTable y
/// agrégala como tarjeta en reports_screen.dart.
ReportTable buildDevicesReport(AppLocalizations l, List<Device> devices) {
  String number(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  return ReportTable(
    title: l.reportDevices,
    headers: [
      l.deviceName,
      l.deviceLocation,
      l.deviceType,
      l.deviceStatus,
      l.deviceThreshold,
      l.deviceLatitude,
      l.deviceLongitude,
    ],
    rows: [
      for (final d in devices)
        [
          d.name,
          d.location,
          d.type.label(l),
          d.status.label(l),
          number(d.threshold),
          d.latitude?.toStringAsFixed(5) ?? '',
          d.longitude?.toStringAsFixed(5) ?? '',
        ],
    ],
  );
}

ReportTable buildAlertsReport(
  AppLocalizations l,
  List<AlertItem> alerts,
  DateFormat dateFormat, {
  bool onlyActive = false,
}) {
  final filtered = onlyActive ? alerts.where((a) => !a.acknowledged) : alerts;

  return ReportTable(
    title: l.reportAlerts,
    headers: [
      l.columnDate,
      l.deviceName,
      l.columnAlert,
      l.columnSeverity,
      l.columnAcknowledged,
    ],
    rows: [
      for (final a in filtered)
        [
          dateFormat.format(a.timestamp),
          a.deviceName,
          a.title,
          a.severity.label(l),
          a.acknowledged ? l.yesLabel : l.noLabel,
        ],
    ],
  );
}
