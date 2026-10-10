import 'app_user.dart';

abstract class AuthRepository {
  Future<AppUser> login(String email, String password);

  /// Devuelve el usuario si hay token válido guardado, o null.
  Future<AppUser?> restoreSession();

  Future<void> logout();
}
