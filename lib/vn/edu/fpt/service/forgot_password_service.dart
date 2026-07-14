import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myfschoolse1911/vn/edu/fpt/model/verify_phone_response.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';

class ForgotPasswordService {
  ForgotPasswordService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AuthService.baseUrl;

  static final ForgotPasswordService instance = ForgotPasswordService();

  static const _requestTimeout = Duration(seconds: 20);

  final http.Client _client;
  final String _baseUrl;

  Future<VerifyPhoneResponse> verifyPhone(String firebaseIdToken) async {
    final token = firebaseIdToken.trim();
    if (token.isEmpty) {
      throw const ApiException(
        'Phiên xác minh không hợp lệ. Vui lòng xác minh OTP lại.',
        statusCode: 401,
      );
    }

    final response = await _post(
      '/auth/forgot-password/verify-phone',
      headers: <String, String>{
        'X-Firebase-ID-Token': token,
        'Content-Type': 'application/json',
      },
    );

    final decoded = _decode(response.body);
    if (_isSuccess(response.statusCode)) {
      final data = _responseData(decoded);
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Phản hồi xác minh không hợp lệ');
      }
      return VerifyPhoneResponse.fromJson(data);
    }

    throw _apiException(
      response.statusCode,
      decoded,
      flow: _ForgotPasswordFlow.verifyPhone,
    );
  }

  Future<String> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (resetToken.trim().isEmpty) {
      throw const ApiException(
        'Quyền đổi mật khẩu không hợp lệ. Vui lòng thực hiện lại.',
        statusCode: 401,
      );
    }

    final response = await _post(
      '/auth/forgot-password/reset',
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: <String, dynamic>{
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    final decoded = _decode(response.body);
    if (_isSuccess(response.statusCode)) {
      return _message(decoded) ?? 'Đổi mật khẩu thành công';
    }

    throw _apiException(
      response.statusCode,
      decoded,
      flow: _ForgotPasswordFlow.reset,
    );
  }

  Future<http.Response> _post(
    String path, {
    required Map<String, String> headers,
    Object? body,
  }) async {
    final normalizedBaseUrl = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBaseUrl$normalizedPath');

    try {
      return await _client
          .post(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException catch (error) {
      throw ApiException('Không thể kết nối đến máy chủ: ${error.message}');
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  dynamic _responseData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        throw ApiException(_message(decoded) ?? 'Yêu cầu không thành công');
      }
      return decoded.containsKey('data') ? decoded['data'] : decoded;
    }
    return decoded;
  }

  ApiException _apiException(
    int statusCode,
    dynamic decoded, {
    required _ForgotPasswordFlow flow,
  }) {
    final backendMessage = _message(decoded);

    if (statusCode == 400) {
      return ApiException(
        backendMessage ?? 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 401) {
      return ApiException(
        flow == _ForgotPasswordFlow.verifyPhone
            ? 'Phiên xác minh không hợp lệ. Vui lòng xác minh OTP lại.'
            : 'Quyền đổi mật khẩu không hợp lệ. Vui lòng thực hiện lại.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 404) {
      return ApiException(
        'Không tìm thấy tài khoản tương ứng với số điện thoại.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 410) {
      return ApiException(
        'Phiên đổi mật khẩu đã hết hạn. Vui lòng thực hiện lại.',
        statusCode: statusCode,
      );
    }
    if (statusCode == 429) {
      return ApiException(
        backendMessage ??
            'Bạn đã thao tác quá nhiều lần. Vui lòng thử lại sau.',
        statusCode: statusCode,
      );
    }
    if (statusCode >= 500) {
      return ApiException(
        'Hệ thống đang gặp lỗi. Vui lòng thử lại sau.',
        statusCode: statusCode,
      );
    }

    return ApiException(
      backendMessage ?? 'Không thể xử lý yêu cầu (mã $statusCode)',
      statusCode: statusCode,
    );
  }

  String? _message(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final directMessage = decoded['message']?.toString().trim();
      if (directMessage != null && directMessage.isNotEmpty) {
        return directMessage;
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final dataMessage = data['message']?.toString().trim();
        if (dataMessage != null && dataMessage.isNotEmpty) {
          return dataMessage;
        }
      }
    }
    return null;
  }
}

enum _ForgotPasswordFlow { verifyPhone, reset }
