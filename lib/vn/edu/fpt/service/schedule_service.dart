import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.semesterName,
    required this.subjectCode,
    required this.subjectName,
    required this.studyDate,
    required this.startTime,
    required this.endTime,
    this.room,
    this.lecturerName,
    this.note,
  });

  final int id;
  final String semesterName;
  final String subjectCode;
  final String subjectName;
  final DateTime studyDate;
  final String startTime;
  final String endTime;
  final String? room;
  final String? lecturerName;
  final String? note;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: _asInt(json['id']),
      semesterName: json['semesterName'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      studyDate:
          DateTime.tryParse(json['studyDate']?.toString() ?? '') ??
          DateTime.now(),
      startTime: _shortTime(json['startTime']),
      endTime: _shortTime(json['endTime']),
      room: _nullableText(json['room']),
      lecturerName: _nullableText(json['lecturerName']),
      note: _nullableText(json['note']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _shortTime(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

class ScheduleService {
  Future<List<ScheduleItem>> fetchScheduleForDate(DateTime studyDate) async {
    final headers = await AuthSession.authorizedHeaders();
    final response = await http.get(
      Uri.parse(
        '${AuthService.baseUrl}/schedules/day',
      ).replace(queryParameters: {'studyDate': _formatDate(studyDate)}),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await AuthSession.clear();
      throw const SessionExpiredException();
    }

    final decoded = _decodeResponse(response.body);
    if (response.statusCode == 200 && decoded['success'] == true) {
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ScheduleItem.fromJson)
            .toList();
      }
      return const <ScheduleItem>[];
    }

    final message = decoded['message']?.toString();
    throw Exception(
      message == null || message.isEmpty ? 'Không thể tải lịch học' : message,
    );
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }

  String _formatDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
