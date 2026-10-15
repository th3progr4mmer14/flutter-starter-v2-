import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/env.dart';
import '../errors/failures.dart';
import '../storage/token_storage.dart';

/// Cliente HTTP para consumir APIs.
///  - agrega el token (o API key) solo a peticiones hacia Env.apiUrl
///  - si recibe 401, renueva el token UNA vez y reintenta la petición
///  - reintenta GET con fallas de red/timeout
///  - avisa si hay o no conexión con el servidor
///  - convierte errores de Dio en [Failure]
///  - desenvuelve { "data": ... } si ApiConfig.dataKey está definido
///
/// Uso:  final json = await client.get('/products', query: {'page': 1});
class ApiClient {
  final Dio dio;
  ApiClient._(this.dio);

  factory ApiClient({
    required TokenStorage tokenStorage,
    required void Function() onUnauthorized,
    required void Function(bool online) onConnectivityChanged,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        sendTimeout: ApiConfig.timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _StatusInterceptor(onConnectivityChanged),
      _RetryInterceptor(dio),
      _AuthInterceptor(
        tokens: tokenStorage,
        dio: dio,
        onUnauthorized: onUnauthorized,
      ),
    ]);

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false, // no imprime el token en la consola
      ));
    }

    return ApiClient._(dio);
  }

  Future<dynamic> get(String path,
          {Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send('GET', path, query: query, cancelToken: cancelToken);

  Future<dynamic> post(String path,
          {Object? data, Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send('POST', path, data: data, query: query, cancelToken: cancelToken);

  Future<dynamic> put(String path,
          {Object? data, Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send('PUT', path, data: data, query: query, cancelToken: cancelToken);

  Future<dynamic> patch(String path,
          {Object? data, Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send('PATCH', path, data: data, query: query, cancelToken: cancelToken);

  Future<dynamic> delete(String path,
          {Object? data, Map<String, dynamic>? query, CancelToken? cancelToken}) =>
      _send('DELETE', path, data: data, query: query, cancelToken: cancelToken);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(method: method),
      );
      return unwrap(res.data);
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  /// Quita el envoltorio { "data": ... } si la API lo usa.
  static dynamic unwrap(dynamic body) {
    final key = ApiConfig.dataKey;
    if (key != null && body is Map && body.containsKey(key)) return body[key];
    return body;
  }
}

// ---------------------------------------------------------------------------
// Interceptores
// ---------------------------------------------------------------------------

/// Avisa si el servidor responde (online) o no hay red (offline).
class _StatusInterceptor extends Interceptor {
  _StatusInterceptor(this.onChanged);
  final void Function(bool online) onChanged;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    onChanged(true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final offline = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
    if (offline) {
      onChanged(false);
    } else if (err.response != null) {
      onChanged(true);
    }
    handler.next(err);
  }
}

/// Reintenta GET cuando falla la red o hay timeout.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this.dio);
  final Dio dio;

  static const _retryable = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final attempt = (opts.extra['retry_attempt'] as int?) ?? 0;

    final canRetry = opts.method.toUpperCase() == 'GET' &&
        _retryable.contains(err.type) &&
        attempt < ApiConfig.maxRetries &&
        opts.cancelToken?.isCancelled != true;

    if (!canRetry) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    opts.extra['retry_attempt'] = attempt + 1;

    try {
      final response = await dio.fetch<dynamic>(opts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Agrega credenciales y renueva el token cuando la API responde 401.
/// Es "queued": si varias peticiones fallan a la vez, se atienden una por una
/// y solo la primera hace el refresh.
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required this.tokens,
    required this.dio,
    required this.onUnauthorized,
  });

  final TokenStorage tokens;
  final Dio dio;
  final void Function() onUnauthorized;

  // Dio aparte, sin interceptores, para no entrar en ciclos al renovar.
  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  late final String _apiHost = Uri.parse(Env.apiUrl).host;

  bool _isApiHost(RequestOptions o) => o.uri.host == _apiHost;

  String _headerValue(String token) => ApiConfig.authScheme.isEmpty
      ? token
      : '${ApiConfig.authScheme} $token';

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Las credenciales solo viajan a TU API, nunca a otros hosts.
    if (_isApiHost(options)) {
      if (Env.apiKey.isNotEmpty) {
        options.headers[ApiConfig.apiKeyHeader] = Env.apiKey;
      }
      final token = await tokens.read();
      if (token != null) {
        options.headers[ApiConfig.authHeader] = _headerValue(token);
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;

    final shouldTryRefresh = err.response?.statusCode == 401 &&
        _isApiHost(opts) &&
        opts.extra['auth_retried'] != true;
    if (!shouldTryRefresh) {
      handler.next(err);
      return;
    }

    // Otra petición en cola ya renovó el token: solo reintenta con el nuevo.
    final current = await tokens.read();
    if (current != null && _headerValue(current) != opts.headers[ApiConfig.authHeader]) {
      await _retry(opts, current, handler);
      return;
    }

    final refresh = await tokens.readRefresh();
    if (refresh == null) {
      // Sin refresh token: la sesión ya no sirve.
      onUnauthorized();
      handler.next(err);
      return;
    }

    try {
      final res = await _refreshDio.post<dynamic>(
        ApiConfig.refreshPath,
        data: {ApiConfig.refreshBodyKey: refresh},
      );

      var body = res.data;
      final key = ApiConfig.dataKey;
      if (key != null && body is Map && body[key] is Map) body = body[key];

      final newAccess = body is Map ? body[ApiConfig.accessTokenKey]?.toString() : null;
      if (newAccess == null) throw StateError('La respuesta de refresh no trae token');

      await tokens.saveTokens(
        access: newAccess,
        refresh: body is Map ? body[ApiConfig.refreshTokenKey]?.toString() : null,
      );
      await _retry(opts, newAccess, handler);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 401 || code == 403) {
        // El refresh token ya no es válido: sesión expirada.
        await tokens.clear();
        onUnauthorized();
      }
      // Si fue un problema de red al renovar, NO cerramos la sesión.
      handler.next(err);
    } catch (_) {
      await tokens.clear();
      onUnauthorized();
      handler.next(err);
    }
  }

  Future<void> _retry(
    RequestOptions opts,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    opts.extra['auth_retried'] = true;
    opts.headers[ApiConfig.authHeader] = _headerValue(token);
    try {
      final response = await dio.fetch<dynamic>(opts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
