class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const login = '/login';

  static const dashboard = '/dashboard';

  static const devices = '/devices';
  static const deviceNew = '/devices/new';
  static String deviceEdit(String id) => '/devices/$id';

  static const map = '/map';
  static const geofences = '/map/geofences';
  static const geofenceNew = '/map/geofences/new';
  static String geofenceEdit(String id) => '/map/geofences/$id';

  static const alerts = '/alerts';
  static const reports = '/reports';

  static const inventario = '/inventario';
  static const inventarioNew = '/inventario/new';
  static String inventarioEdit(String id) => '/inventario/$id';

  static const workOrder = '/work_order';
  static const workOrderNew = '/work_order/new';
  static String workOrderEdit(String id) => '/work_order/$id';

  static const apiDemo = '/api_demo';

  static const settings = '/settings';
  static const settingsAppearance = '/settings/appearance';
  static const settingsNotifications = '/settings/notifications';
  static const settingsMonitoring = '/settings/monitoring';
  static const settingsAbout = '/settings/about';
}
