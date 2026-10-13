import '../../../../core/errors/failures.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  AuthRepositoryImpl(this._remote, this._tokens);

  @override
  Future<AppUser> login(String email, String password) async {
    final data = await _remote.login(email, password);
    await _tokens.save(data['token'] as String);
    return AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<AppUser?> restoreSession() async {
    final token = await _tokens.read();
    if (token == null) return null;

    try {
      final data = await _remote.me();
      return AppUser.fromJson(data);
    } on Failure {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() => _tokens.clear();
}