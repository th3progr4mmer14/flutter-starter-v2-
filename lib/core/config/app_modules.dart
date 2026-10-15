/// PANEL DE MÓDULOS
/// -----------------------------------------------------------------------
/// Cambia los `enableX` a true/false según el proyecto. El router, el menú,
/// el dashboard, los reportes y los servicios de fondo leen los valores
/// "efectivos" de abajo, que ya respetan las dependencias entre módulos.
///
/// Importante: apagar un módulo lo oculta, pero su código y sus paquetes
/// siguen en el repo. Para quitarlos del todo mira el README ("Quitar un
/// módulo por completo").
///
/// Autenticación, ajustes e idiomas son parte del núcleo y no se apagan.
class AppModules {
  AppModules._();

  // ---- Interruptores (edita aquí) ----
  static const bool enableDashboard = true;
  static const bool enableDevices = true;
  static const bool enableAlerts = true;
  static const bool enableMap = true; // necesita Dispositivos
  static const bool enableReports = true; // necesita Dispositivos y/o Alertas
  static const bool enableApiDemo = false; // ejemplo que consume una API publica
  static const bool enableWorkOrder = true;
  static const bool enableInventario = true;

  // ---- Valores efectivos (úsalos en el código, no los de arriba) ----
  static const bool dashboard = enableDashboard;
  static const bool devices = enableDevices;
  static const bool alerts = enableAlerts;
  static const bool map = enableMap && enableDevices;
  static const bool reports = enableReports && (enableDevices || enableAlerts);
  static const bool apiDemo = enableApiDemo;
  static const bool workOrder = enableWorkOrder;
  static const bool inventario = enableInventario;
}
