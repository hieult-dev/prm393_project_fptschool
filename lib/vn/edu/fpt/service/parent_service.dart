import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class ParentService {
  const ParentService({ApiClient client = const ApiClient()})
    : _client = client;

  final ApiClient _client;

  Future<List<LinkedStudent>> fetchLinkedStudents() async {
    final data = await _client.get('/parent/students');
    if (data == null) return const <LinkedStudent>[];
    if (data is! List) {
      throw const FormatException('Invalid linked students response');
    }

    return data
        .map((student) => LinkedStudent.fromJson(_jsonMap(student)))
        .toList(growable: false);
  }
}

Map<String, dynamic> _jsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  throw const FormatException('Invalid linked student entry');
}
