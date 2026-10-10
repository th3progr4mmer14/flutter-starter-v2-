/// Configuración por entorno (se cambia al compilar con --dart-define).
///
///   flutter run                                   -> auth local/mock (sin API)
///   flutter run --dart-define=USE_MOCK_AUTH=false \
///               --dart-define=API_URL=https://mi-api.com
class Env {
  Env._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com',
  );

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
