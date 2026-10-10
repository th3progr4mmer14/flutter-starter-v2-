import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Uso: context.l10n.navDashboard
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
