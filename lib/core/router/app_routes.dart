class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';

  static const dashboard = '/dashboard';

  static const devices = '/devices';
  static const deviceNew = '/devices/new';
  static String deviceEdit(String id) => '/devices/$id';

  static const alerts = '/alerts';

  static const settings = '/settings';
  static const settingsAppearance = '/settings/appearance';
  static const settingsNotifications = '/settings/notifications';
  static const settingsMonitoring = '/settings/monitoring';
  static const settingsAbout = '/settings/about';
}
