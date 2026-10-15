import 'package:dio/dio.dart';

enum FailureType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}

/// Error "limpio" que la UI puede mostrar. Para texto localizado usa
/// `failure.localized(context.l10n)` (ver failure_x.dart).
class Failure implements Exception {
  /// Texto por defecto, o el mensaje que mandó el servidor si [fromServer].
  final String message;
  final int? statusCode;
  final FailureType type;

  /// Errores por campo (422/400): { "email": "ya existe" }.
  final Map<String, String> fieldErrors;

  /// true si [message] viene del backend (se muestra tal cual).
  final bool fromServer;

  const Failure(
    this.message, {
    this.statusCode,
    this.type = FailureType.unknown,
    this.fieldErrors = const {},
    this.fromServer = false,
  });

  bool get isNetwork =>
      type == FailureType.network || type == FailureType.timeout;

  /// Convierte cualquier excepción en Failure.
  factory Failure.from(Object error) {
    if (error is Failure) return error;
    if (error is DioException) return Failure.fromDio(error);
    return const Failure('Ocurrió un error inesperado.');
  }

  factory Failure.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure(
          'Se agotó el tiempo de espera. Intenta de nuevo.',
          type: FailureType.timeout,
        );
      case DioExceptionType.connectionError:
        return const Failure(
          'Sin conexión a internet.',
          type: FailureType.network,
        );
      case DioExceptionType.cancel:
        return const Failure('Solicitud cancelada.', type: FailureType.cancelled);
      case DioExceptionType.badResponse:
        return _fromResponse(e);
      // badCertificate, unknown y cualquier tipo nuevo que agregue Dio.
      default:
        return const Failure('Ocurrió un error inesperado.');
    }
  }

  static Failure _fromResponse(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    String? serverMessage;
    final fields = <String, String>{};

    if (data is Map) {
      final m = data['message'] ?? data['error'] ?? data['detail'];
      if (m is String && m.trim().isNotEmpty) serverMessage = m;

      // { "errors": { "campo": ["mensaje", ...] } } o { "campo": "mensaje" }
      final errors = data['errors'];
      if (errors is Map) {
        errors.forEach((k, v) {
          final text = v is List && v.isNotEmpty ? v.first.toString() : v.toString();
          fields[k.toString()] = text;
        });
      }
    }

    final type = switch (code) {
      401 => FailureType.unauthorized,
      403 => FailureType.forbidden,
      404 => FailureType.notFound,
      400 || 409 || 422 => FailureType.validation,
      final c? when c >= 500 => FailureType.server,
      _ => FailureType.unknown,
    };

    return Failure(
      serverMessage ?? 'Error del servidor ($code).',
      statusCode: code,
      type: type,
      fieldErrors: fields,
      fromServer: serverMessage != null,
    );
  }

  @override
  String toString() => message;
}
