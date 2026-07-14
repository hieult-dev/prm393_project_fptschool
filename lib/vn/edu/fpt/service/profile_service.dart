import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';

class ProfileAcademicSummary {
  const ProfileAcademicSummary({
    required this.semesterId,
    required this.semesterName,
    required this.schoolYear,
    required this.gpa,
    required this.gradedSubjects,
    required this.totalCredits,
  });

  final int? semesterId;
  final String? semesterName;
  final String? schoolYear;
  final double? gpa;
  final int gradedSubjects;
  final int totalCredits;

  factory ProfileAcademicSummary.fromJson(Map<String, dynamic> json) {
    return ProfileAcademicSummary(
      semesterId: (json['semesterId'] as num?)?.toInt(),
      semesterName: json['semesterName']?.toString(),
      schoolYear: json['schoolYear']?.toString(),
      gpa: (json['gpa'] as num?)?.toDouble(),
      gradedSubjects: (json['gradedSubjects'] as num?)?.toInt() ?? 0,
      totalCredits: (json['totalCredits'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileOverview {
  const ProfileOverview({required this.profile, required this.academicSummary});

  final LoginResponse profile;
  final ProfileAcademicSummary academicSummary;
}

class ProfileService {
  const ProfileService({ApiClient client = const ApiClient()})
    : _client = client;

  final ApiClient _client;

  Future<LoginResponse> fetchCurrentProfile() async {
    final data = await _client.get('/profile');
    if (data is! Map) {
      throw const FormatException('Dữ liệu hồ sơ không hợp lệ');
    }
    return LoginResponse.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<ProfileAcademicSummary> fetchAcademicSummary() async {
    final data = await _client.get('/profile/academic-summary');
    if (data is! Map) {
      throw const FormatException('Dữ liệu học tập không hợp lệ');
    }
    return ProfileAcademicSummary.fromJson(
      data.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<ProfileOverview> fetchOverview() async {
    final values = await Future.wait<Object>([
      fetchCurrentProfile(),
      fetchAcademicSummary(),
    ]);
    return ProfileOverview(
      profile: values[0] as LoginResponse,
      academicSummary: values[1] as ProfileAcademicSummary,
    );
  }
}
