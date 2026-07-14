import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class MarkReportSemester {
  MarkReportSemester({
    required this.id,
    required this.name,
    required this.schoolYear,
    required this.startDate,
    required this.endDate,
    required this.grades,
  });

  final int id;
  final String name;
  final String schoolYear;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<MarkReportGrade> grades;

  factory MarkReportSemester.fromJson(Map<String, dynamic> json) {
    final gradesJson = json['grades'];
    return MarkReportSemester(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      schoolYear: json['schoolYear'] as String? ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      grades: gradesJson is List
          ? gradesJson
              .whereType<Map<String, dynamic>>()
              .map(MarkReportGrade.fromJson)
              .toList()
          : <MarkReportGrade>[],
    );
  }

  String get shortName => name.replaceAll(' ', '').toUpperCase();

  bool contains(DateTime date) {
    if (startDate == null || endDate == null) {
      return false;
    }
    final current = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return !current.isBefore(start) && !current.isAfter(end);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

class MarkReportGrade {
  MarkReportGrade({
    required this.id,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.className,
    required this.average,
    required this.letterGrade,
    required this.passed,
  });

  final int id;
  final int subjectId;
  final String subjectCode;
  final String subjectName;
  final String? className;
  final double average;
  final String? letterGrade;
  final bool passed;

  factory MarkReportGrade.fromJson(Map<String, dynamic> json) {
    return MarkReportGrade(
      id: json['id'] as int,
      subjectId: json['subjectId'] as int,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      className: json['className'] as String?,
      average: _parseDouble(json['average']),
      letterGrade: json['letterGrade'] as String?,
      passed: json['passed'] as bool? ?? false,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}

class MarkDetail {
  MarkDetail({
    required this.id,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
    required this.className,
    required this.average,
    required this.letterGrade,
    required this.passed,
    required this.items,
  });

  final int id;
  final int subjectId;
  final String subjectCode;
  final String subjectName;
  final String? className;
  final double average;
  final String? letterGrade;
  final bool passed;
  final List<MarkDetailItem> items;

  factory MarkDetail.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return MarkDetail(
      id: json['id'] as int,
      subjectId: json['subjectId'] as int,
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      className: json['className'] as String?,
      average: MarkReportGrade._parseDouble(json['average']),
      letterGrade: json['letterGrade'] as String?,
      passed: json['passed'] as bool? ?? false,
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(MarkDetailItem.fromJson)
              .toList()
          : <MarkDetailItem>[],
    );
  }
}

class MarkDetailItem {
  MarkDetailItem({
    required this.id,
    required this.gradeCategory,
    required this.gradeItem,
    required this.weight,
    required this.value,
  });

  final int id;
  final String gradeCategory;
  final String gradeItem;
  final double? weight;
  final String? value;

  factory MarkDetailItem.fromJson(Map<String, dynamic> json) {
    final parsedWeight = MarkReportGrade._parseDouble(json['weight']);
    return MarkDetailItem(
      id: json['id'] as int,
      gradeCategory: json['gradeCategory'] as String? ?? '',
      gradeItem: json['gradeItem'] as String? ?? '',
      weight: json['weight'] == null ? null : parsedWeight,
      value: json['value']?.toString(),
    );
  }
}

class MarkReportService {
  MarkReportService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  Future<List<MarkReportSemester>> fetchMarkReport({int? studentId}) async {
    final path = studentId == null
        ? '/student-grades/mark-report'
        : '/parent/students/$studentId/mark-report';
    final data = await _client.get(path);
    if (data is! List) return <MarkReportSemester>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(MarkReportSemester.fromJson)
        .toList();
  }

  Future<MarkDetail> fetchMarkDetail({
    required int gradeId,
    int? studentId,
  }) async {
    final path = studentId == null
        ? '/student-grades/$gradeId/mark-detail'
        : '/parent/students/$studentId/grades/$gradeId/mark-detail';
    final data = await _client.get(path);
    if (data is Map<String, dynamic>) return MarkDetail.fromJson(data);
    throw const ApiException('Dữ liệu chi tiết điểm không hợp lệ');
  }
}
