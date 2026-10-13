import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Módulo de ubicación: mantiene vivos el registro de recorridos y la
    // vigilancia de geocercas mientras la app esté abierta (sin reconstruir
    // la app en cada lectura). Si el proyecto no usa ubicación, borra estas 2 líneas.
    ref.listen(trailsControllerProvider, (_, _) {});
    ref.listen(geofenceMonitorProvider, (_, _) {});

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
