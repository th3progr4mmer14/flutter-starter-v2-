import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/devices/presentation/screens/device_form_screen.dart';
import '../../features/devices/presentation/screens/devices_screen.dart';
import '../../features/map/presentation/screens/geofence_form_screen.dart';
import '../../features/map/presentation/screens/geofences_screen.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/appearance_screen.dart';
import '../../features/settings/presentation/screens/monitoring_screen.dart';
import '../../features/settings/presentation/screens/notifications_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'app_routes.dart';

/// Puente entre Riverpod y go_router: avisa al router cuando cambia la sesión.
class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();

  ref.listen<AuthStatus>(
    authControllerProvider.select((s) => s.status),
    (_, _) => refresh.refresh(),
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;

      switch (status) {
        case AuthStatus.unknown:
          return loc == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          return loc == AppRoutes.login ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          return (loc == AppRoutes.login || loc == AppRoutes.splash)
              ? AppRoutes.dashboard
              : null;
      }
    },
    routes: [
      GoRoute(
          path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.devices,
        builder: (_, _) => const DevicesScreen(),
        routes: [
          // 'new' va antes que ':id' para que no lo confunda con un id.
          GoRoute(path: 'new', builder: (_, _) => const DeviceFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DeviceFormScreen(deviceId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (_, _) => const MapScreen(),
        routes: [
          GoRoute(
            path: 'geofences',
            builder: (_, _) => const GeofencesScreen(),
            routes: [
              // 'new' va antes que ':id'. 'extra' trae el punto del mapa
              // cuando se crea con pulsación larga.
              GoRoute(
                path: 'new',
                builder: (_, state) => GeofenceFormScreen(
                  initialPoint: state.extra is LatLng ? state.extra as LatLng : null,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => GeofenceFormScreen(
                    geofenceId: state.pathParameters['id']),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: AppRoutes.alerts, builder: (_, _) => const AlertsScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
              path: 'appearance',
              builder: (_, _) => const AppearanceScreen()),
          GoRoute(
              path: 'notifications',
              builder: (_, _) => const NotificationsScreen()),
          GoRoute(
              path: 'monitoring',
              builder: (_, _) => const MonitoringScreen()),
          GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
        ],
      ),
    ],
  );
});
