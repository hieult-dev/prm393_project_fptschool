import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';

class LoginResponse {
  final int id;
  final String studentCode;
  final String fullName;
  final String email;
  final String? phone;
  final String? className;
  final String role;
  final String status;

  LoginResponse({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.email,
    this.phone,
    this.className,
    required this.role,
    required this.status,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final id = _parseId(json['id']);
    final userName = _stringValue(json['userName']);
    final firstName = _stringValue(json['firstName']);
    final lastName = _stringValue(json['lastName']);
    final roles = _stringList(json['roles']);

    return LoginResponse(
      id: id,
      // The backend renamed studentCode/fullName to
      // userName/firstName/lastName. Keep the app model compatible with both
      // response formats so an absent legacy field is not cast from null.
      studentCode: _stringValue(json['studentCode']).isNotEmpty
          ? _stringValue(json['studentCode'])
          : userName,
      fullName: _stringValue(json['fullName']).isNotEmpty
          ? _stringValue(json['fullName'])
          : [firstName, lastName].where((part) => part.isNotEmpty).join(' '),
      email: _stringValue(json['email']),
      phone: _nullableString(json['phone']),
      className: _nullableString(json['className']),
      role: _stringValue(json['role']).isNotEmpty
          ? _stringValue(json['role'])
          : (roles.isEmpty ? '' : roles.first),
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
}

class AuthService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return kIsWeb
        ? 'http://localhost:8080/api'
        : 'http://10.33.73.234:8080/api';
  }

  Future<LoginResponse> login({
    required String userName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'password': password}),
    );

    String? tryParseMessage(String body) {
      try {
        final jsonResponse = jsonDecode(body);
        if (jsonResponse is Map && jsonResponse.containsKey('message')) {
          return jsonResponse['message']?.toString();
        }
      } catch (_) {}
      return null;
    }

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == true) {
        final data = jsonResponse['data'];
        if (data is! Map<String, dynamic>) {
          throw Exception('Dữ liệu đăng nhập không hợp lệ');
        }

        final accessToken = data['accessToken']?.toString();
        final user = data['user'];
        if (accessToken == null ||
            accessToken.isEmpty ||
            user is! Map<String, dynamic>) {
          throw Exception('Phản hồi đăng nhập không chứa JWT hợp lệ');
        }

        await AuthSession.saveAccessToken(accessToken);
        return LoginResponse.fromJson(user);
      } else {
        final msg = jsonResponse['message']?.toString() ?? 'Đăng nhập thất bại';
        throw Exception(msg);
      }
    } else {
      final backendMsg = tryParseMessage(response.body);
      if (backendMsg != null && backendMsg.isNotEmpty) {
        throw Exception(backendMsg);
      }

      if (response.statusCode == 401) {
        throw Exception('Tài khoản hoặc mật khẩu không chính xác');
      } else if (response.statusCode == 404) {
        throw Exception('Người dùng không tồn tại');
      } else {
        throw Exception('Đăng nhập thất bại (mã ${response.statusCode})');
      }
    }
  }

  Future<void> logout() => AuthSession.clear();
}
