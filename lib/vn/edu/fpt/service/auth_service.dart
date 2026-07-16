import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';

class LoginResponse {
  final int id;
  final String userName;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? className;
  final String? teacherTitle;
  final String role;
  final List<String> roles;
  final List<String> permissions;
  final String status;

  LoginResponse({
    required this.id,
    required this.userName,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.className,
    this.teacherTitle,
    required this.role,
    required this.roles,
    required this.permissions,
    required this.status,
  });

  String get studentCode => userName;

  String get fullName =>
      [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

  bool hasRole(String value) => roles.contains(value.trim().toUpperCase());

  String get primaryRole {
    for (final supportedRole in const [
      'HOMEROOM_TEACHER',
      'SUBJECT_TEACHER',
      'TEACHER',
      'PARENT',
      'STUDENT',
    ]) {
      if (hasRole(supportedRole)) return supportedRole;
    }
    return role;
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['id']);
    final userName = _stringValue(json['userName']);
    final firstName = _stringValue(json['firstName']);
    final lastName = _stringValue(json['lastName']);
    final declaredRole = _stringValue(json['role']).toUpperCase();
    final parsedRoles = _stringList(
      json['roles'],
    ).map((value) => value.toUpperCase()).toList();
    final roles = <String>{
      ...parsedRoles,
      if (declaredRole.isNotEmpty) declaredRole,
    }.toList(growable: false);

    return LoginResponse(
      id: id,
      // Keep the parser compatible with the legacy response while exposing a
      // role-neutral userName to the rest of the application.
      userName: _stringValue(json['studentCode']).isNotEmpty
          ? _stringValue(json['studentCode'])
          : userName,
      firstName: firstName.isNotEmpty
          ? firstName
          : _legacyFirstName(_stringValue(json['fullName'])),
      lastName: lastName.isNotEmpty
          ? lastName
          : _legacyLastName(_stringValue(json['fullName'])),
      email: _stringValue(json['email']),
      phone: _nullableString(json['phone']),
      className: _nullableString(json['className']),
      teacherTitle: _nullableString(json['teacherTitle']),
      role: declaredRole.isNotEmpty
          ? declaredRole
          : (roles.isEmpty ? '' : roles.first),
      roles: roles,
      permissions: _stringList(
        json['permissions'],
      ).map((value) => value.toUpperCase()).toList(growable: false),
      status: _stringValue(json['status']),
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;

    throw const FormatException(
      'Dữ liệu đăng nhập không hợp lệ: thiếu mã người dùng',
    );
  }

  static String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  static String? _nullableString(dynamic value) {
    final result = _stringValue(value);
    return result.isEmpty ? null : result;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map(_stringValue).where((item) => item.isNotEmpty).toList();
  }

  static String _legacyFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(RegExp(r'\s+'));
    return parts.first;
  }

  static String _legacyLastName(String fullName) {
    if (fullName.isEmpty) return '';
    final parts = fullName.split(RegExp(r'\s+'));
    return parts.length <= 1 ? '' : parts.skip(1).join(' ');
  }
}

class AuthService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const _requestTimeout = Duration(seconds: 20);
  static Future<String>? _refreshInFlight;

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return kIsWeb
        ? 'http://localhost:8080/api'
        : 'http://192.168.1.11:8080/api';
  }

  Future<LoginResponse> login({
    required String userName,
    required String password,
  }) async {
    final response = await _post('/auth/login', <String, dynamic>{
      'userName': userName,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = _authData(response, 'Dữ liệu đăng nhập không hợp lệ');
      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw Exception('Dữ liệu đăng nhập không chứa người dùng hợp lệ');
      }

      await _saveTokens(data);
      return LoginResponse.fromJson(user);
    }

    final backendMessage = _tryParseMessage(response.body);
    if (backendMessage != null && backendMessage.isNotEmpty) {
      throw Exception(backendMessage);
    }
    if (response.statusCode == 401) {
      throw Exception('Tài khoản hoặc mật khẩu không chính xác');
    }
    if (response.statusCode == 404) {
      throw Exception('Người dùng không tồn tại');
    }
    throw Exception('Đăng nhập thất bại (mã ${response.statusCode})');
  }

  static Future<String> refreshAccessToken() async {
    final current = _refreshInFlight;
    if (current != null) return await current;

    final refresh = _refresh();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  static Future<String> _refresh() async {
    final refreshToken = await AuthSession.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await AuthSession.clear();
      throw const SessionExpiredException();
    }

    final response = await _post('/auth/refresh', <String, dynamic>{
      'refreshToken': refreshToken,
    });
    if (response.statusCode == 400 || response.statusCode == 401) {
      await AuthSession.clear();
      throw const SessionExpiredException();
    }
    if (response.statusCode != 200) {
      throw Exception(
        _tryParseMessage(response.body) ??
            'Không thể làm mới phiên đăng nhập (mã ${response.statusCode})',
      );
    }

    try {
      final data = _authData(response, 'Phản hồi refresh token không hợp lệ');
      await _saveTokens(data);
      return data['accessToken']!.toString();
    } on SessionExpiredException {
      rethrow;
    } catch (_) {
      await AuthSession.clear();
      throw const SessionExpiredException();
    }
  }

  Future<void> logout() async {
    final refreshToken = await AuthSession.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _post('/auth/logout', <String, dynamic>{
          'refreshToken': refreshToken,
        });
      }
    } catch (_) {
      // Local logout must still complete if the server cannot be reached.
    } finally {
      await AuthSession.clear();
    }
  }

  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      return await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw Exception('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException catch (error) {
      throw Exception('Không thể kết nối đến máy chủ: ${error.message}');
    }
  }

  static Map<String, dynamic> _authData(
    http.Response response,
    String invalidMessage,
  ) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception(_tryParseMessage(response.body) ?? invalidMessage);
    }
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception(invalidMessage);
    }
    return data;
  }

  static Future<void> _saveTokens(Map<String, dynamic> data) async {
    final accessToken = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw Exception('Phản hồi đăng nhập không chứa token hợp lệ');
    }
    await AuthSession.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static String? _tryParseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded.containsKey('message')) {
        return decoded['message']?.toString();
      }
    } catch (_) {}
    return null;
  }
}
