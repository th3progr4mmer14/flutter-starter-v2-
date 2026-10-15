// ignore_for_file: unintended_html_in_doc_comment

/// AJUSTES DE LA API
/// -----------------------------------------------------------------------
/// Cada API trae sus propias reglas. Cuando recibas una nueva, revisa este
/// archivo contra su documentación (Swagger / Postman) y ajusta lo que difiera.
/// Todo el cliente HTTP (ApiClient), el refresco de token y la paginación
/// leen de aquí.
class ApiConfig {
  ApiConfig._();

  // ---- Autenticación ----
  /// Nombre del header donde viaja el token.
  static const String authHeader = 'Authorization';

  /// Esquema del token: 'Bearer' -> "Authorization: Bearer <token>".
  /// Déjalo en '' si la API espera el token solo, sin prefijo.
  static const String authScheme = 'Bearer';

  /// Header para APIs con API key (se manda si pasas --dart-define=API_KEY=...).
  static const String apiKeyHeader = 'X-API-Key';

  /// Llaves del JSON de login/refresh que traen los tokens.
  static const String accessTokenKey = 'token';
  static const String refreshTokenKey = 'refresh_token';

  /// Endpoint de renovación y nombre del campo con el refresh token.
  static const String refreshPath = '/auth/refresh';
  static const String refreshBodyKey = 'refresh_token';

  // ---- Formato de respuesta ----
  /// Si la API envuelve todo en { "data": ... } pon 'data'; si no, null.
  static const String? dataKey = null;

  // ---- Paginación ----
  static const String pageParam = 'page';
  static const String limitParam = 'limit';
  static const int defaultPageSize = 20;

  /// Llaves cuando la lista viene en un objeto: { "items": [...], "total": 120 }.
  static const List<String> itemsKeys = ['items', 'results', 'data', 'content'];
  static const String totalKey = 'total';

  // ---- Red ----
  /// Reintentos automáticos para GET con fallas de red o timeout.
  static const int maxRetries = 2;
  static const Duration timeout = Duration(seconds: 15);
}
