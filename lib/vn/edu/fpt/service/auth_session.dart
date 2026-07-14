import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException([
    this.message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class AuthSession {
  AuthSession._();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  static Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  static Future<Map<String, String>> authorizedHeaders() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }
    return <String, String>{'Authorization': 'Bearer $token'};
  }
}
