import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

enum ScheduleScope { student, parent, teacher }

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    this.semesterId = 0,
    required this.semesterName,
    this.subjectId = 0,
    required this.subjectCode,
    required this.subjectName,
    required this.studyDate,
    required this.startTime,
    required this.endTime,
    this.room,
    this.lecturerName,
    this.note,
    this.studentCount,
    this.classNames = const [],
  });

  final int id;
  final int semesterId;
  final String semesterName;
  final int subjectId;
  final String subjectCode;
  final String subjectName;
  final DateTime studyDate;
  final String startTime;
  final String endTime;
  final String? room;
  final String? lecturerName;
  final String? note;
  final int? studentCount;
  final List<String> classNames;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: _asInt(json['id']),
      semesterId: _asInt(json['semesterId']),
      semesterName: json['semesterName'] as String? ?? '',
      subjectId: _asInt(json['subjectId']),
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      studyDate:
          DateTime.tryParse(json['studyDate']?.toString() ?? '') ??
          (throw const FormatException('Ngày của lịch học không hợp lệ')),
      startTime: _shortTime(json['startTime']),
      endTime: _shortTime(json['endTime']),
      room: _nullableText(json['room']),
      lecturerName: _nullableText(json['lecturerName']),
      note: _nullableText(json['note']),
      studentCount: json['studentCount'] == null
          ? null
          : _asInt(json['studentCount']),
      classNames: json['classNames'] is List
          ? (json['classNames'] as List)
                .map((value) => value?.toString().trim() ?? '')
                .where((value) => value.isNotEmpty)
                .toList(growable: false)
          : const [],
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
  ScheduleService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  Future<List<ScheduleItem>> fetchScheduleForDate(
    DateTime studyDate, {
    ScheduleScope scope = ScheduleScope.student,
    int? studentId,
  }) async {
    final data = await _client.get(
      _path(scope: scope, studentId: studentId, period: 'day'),
      queryParameters: {'studyDate': _formatDate(studyDate)},
    );
    return _parseItems(data);
  }

  Future<List<ScheduleItem>> fetchWeeklySchedule(
    DateTime weekStart, {
    ScheduleScope scope = ScheduleScope.student,
    int? studentId,
  }) async {
    final data = await _client.get(
      _path(scope: scope, studentId: studentId, period: 'weekly'),
      queryParameters: {'weekStart': _formatDate(weekStart)},
    );
    return _parseItems(data);
  }

  String _path({
    required ScheduleScope scope,
    required String period,
    int? studentId,
  }) {
    return switch (scope) {
      ScheduleScope.student => '/schedules/$period',
      ScheduleScope.teacher => '/teacher/schedules/$period',
      ScheduleScope.parent =>
        studentId == null
            ? throw ArgumentError('studentId is required for a parent schedule')
            : '/parent/students/$studentId/schedules/$period',
    };
  }

  List<ScheduleItem> _parseItems(dynamic data) {
    if (data is! List) {
      throw const FormatException('Dữ liệu lịch học không hợp lệ');
    }
    return data
        .map((item) => ScheduleItem.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw const FormatException('Phần tử lịch học không hợp lệ');
  }

  static String _formatDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
