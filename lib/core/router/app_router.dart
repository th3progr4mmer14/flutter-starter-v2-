import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/screens/alerts_screen.dart';
import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/devices/presentation/screens/device_form_screen.dart';
import '../../features/devices/presentation/screens/devices_screen.dart';
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
    (_, __) => refresh.refresh(),
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
          path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.devices,
        builder: (_, __) => const DevicesScreen(),
        routes: [
          // 'new' va antes que ':id' para que no lo confunda con un id.
          GoRoute(path: 'new', builder: (_, __) => const DeviceFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                DeviceFormScreen(deviceId: state.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.alerts, builder: (_, __) => const AlertsScreen()),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
              path: 'appearance',
              builder: (_, __) => const AppearanceScreen()),
          GoRoute(
              path: 'notifications',
              builder: (_, __) => const NotificationsScreen()),
          GoRoute(
              path: 'monitoring',
              builder: (_, __) => const MonitoringScreen()),
          GoRoute(path: 'about', builder: (_, __) => const AboutScreen()),
        ],
      ),
    ],
  );
});
