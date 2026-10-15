import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'auth_token';
  static const _refreshKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;
  const TokenStorage(this._storage);

  Future<String?> read() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> save(String token) =>
      _storage.write(key: _accessKey, value: token);

  /// Guarda el access token y, si viene, el refresh token.
  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
