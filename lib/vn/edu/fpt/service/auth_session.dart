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
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<void> clear() {
    return _storage.delete(key: _accessTokenKey);
  }

  static Future<Map<String, String>> authorizedHeaders() async {
    final token = await readAccessToken();
    if (token == null || token.isEmpty) {
      throw const SessionExpiredException();
    }
    return <String, String>{'Authorization': 'Bearer $token'};
  }
}
