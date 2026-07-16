import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient();

  static const _requestTimeout = Duration(seconds: 20);

  Future<dynamic> get(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) {
    return _send('GET', path, queryParameters: queryParameters);
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?> queryParameters = const {},
    Object? body,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final configuredBaseUrl = AuthService.baseUrl;
    final baseUrl = configuredBaseUrl.endsWith('/')
        ? configuredBaseUrl.substring(0, configuredBaseUrl.length - 1)
        : configuredBaseUrl;
    final query = <String, String>{
      for (final entry in queryParameters.entries)
        if (entry.value != null && entry.value.toString().isNotEmpty)
          entry.key: entry.value.toString(),
    };
    final uri = Uri.parse(
      '$baseUrl$normalizedPath',
    ).replace(queryParameters: query.isEmpty ? null : query);
    var headers = await _authorizedHeaders();
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    try {
      var response = await _request(method, uri, headers, body);

      if (response.statusCode == 401) {
        final accessToken = await AuthService.refreshAccessToken();
        headers = <String, String>{
          ...headers,
          'Authorization': 'Bearer $accessToken',
        };
        response = await _request(method, uri, headers, body);
        if (response.statusCode == 401) {
          await AuthSession.clear();
          throw const SessionExpiredException();
        }
      }

      final decoded = _decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          if (decoded['success'] == false) {
            throw ApiException(
              _message(decoded, 'Yêu cầu không thành công'),
              statusCode: response.statusCode,
            );
          }
          return decoded.containsKey('data') ? decoded['data'] : decoded;
        }
        return decoded;
      }

      throw ApiException(
        decoded is Map<String, dynamic>
            ? _message(decoded, 'Không thể xử lý yêu cầu')
            : 'Không thể xử lý yêu cầu (mã ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SessionExpiredException {
      rethrow;
    } on ApiException {
      rethrow;
    } on http.ClientException catch (error) {
      throw ApiException('Không thể kết nối đến máy chủ: ${error.message}');
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    }
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    try {
      return await AuthSession.authorizedHeaders();
    } on SessionExpiredException {
      final accessToken = await AuthService.refreshAccessToken();
      return <String, String>{'Authorization': 'Bearer $accessToken'};
    }
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    Map<String, String> headers,
    Object? body,
  ) {
    final encodedBody = body == null ? null : jsonEncode(body);
    return switch (method) {
      'POST' =>
        http
            .post(uri, headers: headers, body: encodedBody)
            .timeout(_requestTimeout),
      'PUT' =>
        http
            .put(uri, headers: headers, body: encodedBody)
            .timeout(_requestTimeout),
      'PATCH' =>
        http
            .patch(uri, headers: headers, body: encodedBody)
            .timeout(_requestTimeout),
      'DELETE' => http.delete(uri, headers: headers).timeout(_requestTimeout),
      _ => http.get(uri, headers: headers).timeout(_requestTimeout),
    };
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  String _message(Map<String, dynamic> json, String fallback) {
    final message = json['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }
}
