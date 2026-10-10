import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// Auth sin backend: sirve para desarrollar la UI y el flujo de sesión.
/// Acepta cualquier correo/contraseña válidos y guarda la sesión en el
/// dispositivo. Reemplázalo por AuthRepositoryImpl cuando tengas API.
class LocalAuthRepository implements AuthRepository {
  static const _userKey = 'local_user';

  final FlutterSecureStorage _storage;
  const LocalAuthRepository(this._storage);

  @override
  Future<AppUser> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // simula red
    final user = AppUser(id: '1', name: email.split('@').first, email: email);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<AppUser?> restoreSession() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> logout() => _storage.delete(key: _userKey);
}
