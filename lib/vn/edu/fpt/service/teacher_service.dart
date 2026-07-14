import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class TeacherService {
  const TeacherService({ApiClient client = const ApiClient()})
    : _client = client;

  final ApiClient _client;

  Future<List<SchoolSemester>> fetchSemesters() async {
    final data = await _client.get('/teacher/semesters');
    return _parseList(data, SchoolSemester.fromJson, 'semesters');
  }

  Future<List<SchoolSubject>> fetchSubjects({int? semesterId}) async {
    final data = await _client.get(
      '/teacher/subjects',
      queryParameters: <String, Object?>{'semesterId': ?semesterId},
    );
    return _parseList(data, SchoolSubject.fromJson, 'subjects');
  }

  Future<List<LinkedStudent>> fetchStudents({
    int? subjectId,
    int? semesterId,
    String? search,
  }) async {
    final trimmedSearch = search?.trim();
    final normalizedSearch = trimmedSearch == null || trimmedSearch.isEmpty
        ? null
        : trimmedSearch;
    final data = await _client.get(
      '/teacher/students',
      queryParameters: <String, Object?>{
        'subjectId': ?subjectId,
        'semesterId': ?semesterId,
        'search': ?normalizedSearch,
      },
    );
    return _parseList(data, LinkedStudent.fromJson, 'students');
  }

  Future<List<TeacherGrade>> fetchGrades({
    int? userId,
    int? semesterId,
    int? subjectId,
  }) async {
    final data = await _client.get(
      '/teacher/grades',
      queryParameters: <String, Object?>{
        'userId': ?userId,
        'semesterId': ?semesterId,
        'subjectId': ?subjectId,
      },
    );
    return _parseList(data, TeacherGrade.fromJson, 'grades');
  }

  Future<TeacherGrade> createGrade({
    required int userId,
    required int subjectId,
    required int semesterId,
    required List<TeacherGradeItem> items,
  }) async {
    final data = await _client.post(
      '/teacher/grades',
      body: _gradePayload(
        userId: userId,
        subjectId: subjectId,
        semesterId: semesterId,
        items: items,
      ),
    );
    return TeacherGrade.fromJson(_jsonMap(data, 'created grade'));
  }

  Future<TeacherGrade> updateGrade({
    required int gradeId,
    required int userId,
    required int subjectId,
    required int semesterId,
    required List<TeacherGradeItem> items,
  }) async {
    final data = await _client.put(
      '/teacher/grades/$gradeId',
      body: _gradePayload(
        userId: userId,
        subjectId: subjectId,
        semesterId: semesterId,
        items: items,
      ),
    );
    return TeacherGrade.fromJson(_jsonMap(data, 'updated grade'));
  }

  Future<void> deleteGrade(int gradeId) {
    return _client.delete('/teacher/grades/$gradeId');
  }

  Map<String, dynamic> _gradePayload({
    required int userId,
    required int subjectId,
    required int semesterId,
    required List<TeacherGradeItem> items,
  }) {
    return <String, dynamic>{
      'userId': userId,
      'subjectId': subjectId,
      'semesterId': semesterId,
      'items': items
          .map((item) => item.toRequestJson())
          .toList(growable: false),
    };
  }
}

List<T> _parseList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
  String fieldName,
) {
  if (data == null) return <T>[];
  if (data is! List) {
    throw FormatException('Invalid $fieldName response');
  }
  return data
      .map((item) => fromJson(_jsonMap(item, fieldName)))
      .toList(growable: false);
}

Map<String, dynamic> _jsonMap(dynamic value, String fieldName) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw FormatException('Invalid $fieldName entry');
}
