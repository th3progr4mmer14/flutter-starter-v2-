import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_modules.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/map/presentation/providers/geofence_monitor.dart';
import 'features/map/presentation/providers/trails_controller.dart';
import 'features/settings/presentation/providers/settings_controller.dart';
import 'l10n/l10n_x.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsControllerProvider);

    // Servicios de fondo de los módulos (ver core/config/app_modules.dart).
    // Con listen se mantienen vivos sin reconstruir la app en cada lectura.
    if (AppModules.map) {
      ref.listen(trailsControllerProvider, (_, _) {});
    }
    if (AppModules.map && AppModules.alerts) {
      ref.listen(geofenceMonitorProvider, (_, _) {});
    }

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale, // null = idioma del sistema
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
