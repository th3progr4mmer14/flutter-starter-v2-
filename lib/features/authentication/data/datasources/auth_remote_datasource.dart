import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';

/// Ajusta los endpoints al backend.
class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  /// Espera: { "token": "...", "user": { "id", "name", "email" } }
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> me() async {
    try {
      final res = await _dio.get('/auth/me');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}