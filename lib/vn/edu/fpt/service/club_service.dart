import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';

class ClubService {
  const ClubService({ApiClient client = const ApiClient()}) : _client = client;

  final ApiClient _client;

  Future<List<SchoolClub>> fetchActiveClubs() async {
    final data = await _client.get(
      '/clubs/search',
      queryParameters: const <String, Object?>{'status': 'ACTIVE'},
    );
    if (data is! List) {
      throw const FormatException('Dữ liệu câu lạc bộ không hợp lệ');
    }
    return data
        .map((item) => SchoolClub.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw const FormatException('Phần tử câu lạc bộ không hợp lệ');
  }
}
