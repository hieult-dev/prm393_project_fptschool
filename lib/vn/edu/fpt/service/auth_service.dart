import 'dart:convert';
import 'package:http/http.dart' as http;

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
    return LoginResponse(
      id: json['id'] as int,
      studentCode: json['studentCode'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      className: json['className'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
    );
  }
}

class AuthService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.11:8080/api',
  );

  Future<LoginResponse> login({
    required String studentCode,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'studentCode': studentCode,
        'password': password,
      }),
    );

    // Helper to try extract backend "message" field from JSON body
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
        return LoginResponse.fromJson(jsonResponse['data']);
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
}
