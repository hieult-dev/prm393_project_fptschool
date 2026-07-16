import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class ExamScheduleService {
  const ExamScheduleService({ApiClient client = const ApiClient()})
    : _client = client;

  final ApiClient _client;

  Future<List<ExamScheduleItem>> fetchMyExamSchedule({int? semesterId}) async {
    final data = await _client.get(
      '/exam-schedules/me',
      queryParameters: <String, Object?>{'semesterId': semesterId},
    );
    if (data is! List) {
      throw const FormatException('Invalid exam schedule data');
    }
    return data
        .map((item) => ExamScheduleItem.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw const FormatException('Invalid exam schedule item');
  }
}
