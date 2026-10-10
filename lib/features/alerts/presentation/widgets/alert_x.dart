import 'package:flutter/material.dart';

import '../../../../l10n/l10n_x.dart';
import '../../domain/alert_item.dart';

extension AlertSeverityX on AlertSeverity {
  String label(AppLocalizations l) => switch (this) {
        AlertSeverity.info => l.severityInfo,
        AlertSeverity.warning => l.severityWarning,
        AlertSeverity.critical => l.severityCritical,
      };

  Color get color => switch (this) {
        AlertSeverity.info => Colors.blue,
        AlertSeverity.warning => Colors.orange,
        AlertSeverity.critical => Colors.red,
      };

  IconData get icon => switch (this) {
        AlertSeverity.info => Icons.info_outline,
        AlertSeverity.warning => Icons.warning_amber_rounded,
        AlertSeverity.critical => Icons.error_outline,
      };
}
