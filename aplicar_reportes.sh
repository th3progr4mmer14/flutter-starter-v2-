#!/usr/bin/env bash
# Ejecutar desde la RAIZ del proyecto, despues de copiar la carpeta lib/ del zip.
set -e

flutter pub add pdf file_saver

# flutter pub add puede borrar esta linea: se vuelve a poner si falta
grep -q "generate: true" pubspec.yaml || \
  sed -i 's/^  uses-material-design: true/  generate: true\n  uses-material-design: true/' pubspec.yaml

R=lib/core/router/app_routes.dart
M=lib/shared/widgets/app_menu.dart
T=lib/core/router/app_router.dart

# 1) constante de ruta
grep -q "reports" "$R" || \
  sed -i "s#^\(\s*\)static const alerts = '/alerts';#\1static const alerts = '/alerts';\n\1static const reports = '/reports';#" "$R"

# 2) entrada en el menu (antes de Ajustes)
grep -q "AppRoutes.reports" "$M" || \
  sed -i "s#^\(\s*\)(AppRoutes.settings, Icons.settings_outlined, l.navSettings),#\1(AppRoutes.reports, Icons.description_outlined, l.navReports),\n\1(AppRoutes.settings, Icons.settings_outlined, l.navSettings),#" "$M"

# 3) import y ruta en el router
grep -q "reports_screen" "$T" || \
  sed -i "/alerts_screen.dart';/a import '../../features/reports/presentation/screens/reports_screen.dart';" "$T"
grep -q "AppRoutes.reports" "$T" || \
  sed -i "s#^\(\s*\)GoRoute(path: AppRoutes.alerts,#\1GoRoute(path: AppRoutes.reports, builder: (_, _) => const ReportsScreen()),\n\1GoRoute(path: AppRoutes.alerts,#" "$T"

flutter pub get
flutter gen-l10n

echo
echo "Listo. Revisa los 3 cambios:"
grep -n "reports" "$R" "$M" "$T"
