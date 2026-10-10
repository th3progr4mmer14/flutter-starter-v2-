import 'package:dio/dio.dart';

/// Error "limpio" que la UI puede mostrar tal cual.
class Failure implements Exception {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  factory Failure.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure('Se agotó el tiempo de espera. Intenta de nuevo.');
      case DioExceptionType.connectionError:
        return const Failure('Sin conexión a internet.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        final serverMsg = data is Map ? data['message']?.toString() : null;
        if (code == 401) {
          return Failure(serverMsg ?? 'Credenciales inválidas.',
              statusCode: code);
        }
        return Failure(serverMsg ?? 'Error del servidor ($code).',
            statusCode: code);
      default:
        return const Failure('Ocurrió un error inesperado.');
    }
  }

  @override
  String toString() => message;
}
