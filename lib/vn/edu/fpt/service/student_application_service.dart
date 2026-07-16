import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class StudentApplicationService {
  const StudentApplicationService({ApiClient client = const ApiClient()})
    : _client = client;

  final ApiClient _client;

  Future<List<ApplicationType>> fetchApplicationTypes() async {
    final data = await _client.get('/application-types');
    return _parseList(data, ApplicationType.fromJson, 'application types');
  }

  Future<List<StudentApplication>> fetchApplications({
    required int studentId,
    String? status,
  }) async {
    final data = await _client.get(
      '/parent/students/$studentId/applications',
      queryParameters: <String, Object?>{'status': status},
    );
    return _parseList(data, StudentApplication.fromJson, 'applications');
  }

  Future<StudentApplication> createApplication({
    required int studentId,
    required int applicationTypeId,
    required String title,
    required String content,
  }) async {
    final data = await _client.post(
      '/parent/students/$studentId/applications',
      body: <String, dynamic>{
        'applicationTypeId': applicationTypeId,
        'title': title.trim(),
        'content': content.trim(),
      },
    );
    return StudentApplication.fromJson(_jsonMap(data, 'created application'));
  }

  Future<List<StudentApplication>> fetchTeacherApplications({
    String? status,
  }) async {
    final data = await _client.get(
      '/teacher/applications',
      queryParameters: <String, Object?>{'status': status},
    );
    return _parseList(data, StudentApplication.fromJson, 'applications');
  }

  Future<StudentApplication> reviewTeacherApplication({
    required int applicationId,
    required String status,
    String? responseNote,
  }) async {
    final data = await _client.patch(
      '/teacher/applications/$applicationId/review',
      body: <String, dynamic>{
        'status': status.trim().toUpperCase(),
        'responseNote': responseNote?.trim(),
      },
    );
    return StudentApplication.fromJson(_jsonMap(data, 'reviewed application'));
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
    String fieldName,
  ) {
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
}
