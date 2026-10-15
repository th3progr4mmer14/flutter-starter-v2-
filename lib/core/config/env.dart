/// Configuración por entorno (se cambia al compilar con --dart-define).
///
///   flutter run                                   -> auth local/mock (sin API)
///   flutter run --dart-define=USE_MOCK_AUTH=false \
///               --dart-define=API_URL=https://mi-api.com \
///               --dart-define=API_KEY=xxxx        (solo si la API usa API key)
class Env {
  Env._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com',
  );

  /// API key opcional. Si está vacía no se envía.
  static const String apiKey = String.fromEnvironment('API_KEY');

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );

  /// true = login local sin backend. Ponlo en false cuando tengas API.
  static const bool useMockAuth = bool.fromEnvironment(
    'USE_MOCK_AUTH',
    defaultValue: true,
  );

  static bool get isProd => flavor == 'prod';
}
