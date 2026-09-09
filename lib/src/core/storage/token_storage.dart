import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = 900,
  });
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
}

class TokenStorage {
  const TokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> save(TokenPair pair) async {
    await _storage.write(key: _accessKey, value: pair.accessToken);
    await _storage.write(key: _refreshKey, value: pair.refreshToken);
  }

  Future<void> clear() => _storage.deleteAll();
}
