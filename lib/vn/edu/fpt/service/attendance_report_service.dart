import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class AttendanceReportService {
  const AttendanceReportService({ApiClient client = const ApiClient()})
    : _client = client;

  final ApiClient _client;

  Future<List<AttendanceReportSemester>> fetchMyAttendanceReport() async {
    final data = await _client.get('/attendance-reports/me');
    if (data is! List) {
      throw const FormatException('Invalid attendance report data');
    }
    return data
        .map((item) => AttendanceReportSemester.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw const FormatException('Invalid attendance report item');
  }
}
