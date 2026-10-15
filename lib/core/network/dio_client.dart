import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/env.dart';
import '../storage/token_storage.dart';

/// Dio básico (lo usa el login). Para el resto de las llamadas usa ApiClient,
/// que además renueva el token, reintenta y mapea errores.
Dio createDio(TokenStorage tokenStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final apiHost = Uri.parse(Env.apiUrl).host;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // El token solo viaja a TU API, nunca a otros hosts.
        if (options.uri.host == apiHost) {
          if (Env.apiKey.isNotEmpty) {
            options.headers[ApiConfig.apiKeyHeader] = Env.apiKey;
          }
          final token = await tokenStorage.read();
          if (token != null) {
            options.headers[ApiConfig.authHeader] = ApiConfig.authScheme.isEmpty
                ? token
                : '${ApiConfig.authScheme} $token';
          }
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false, // no imprime el token en la consola
    ));
  }

  return dio;
}
