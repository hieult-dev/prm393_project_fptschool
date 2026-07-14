import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/profile_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';

void main() {
  testWidgets('renders profile information and reveals masked values', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(service: _FakeProfileService(_studentProfile())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lê Trung Hiếu'), findsOneWidget);
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Kết quả học tập'), findsOneWidget);
    expect(find.text('Học kỳ hiện tại'), findsOneWidget);
    expect(find.text('Summer 2026'), findsOneWidget);
    expect(find.text('8.25'), findsOneWidget);
    expect(find.text('Thẻ sinh viên'), findsNothing);
    expect(find.text('HE1***408'), findsOneWidget);
    expect(find.byTooltip('Cá nhân'), findsOneWidget);

    await tester.tap(find.byTooltip('Hiện thông tin').first);
    await tester.pump();

    expect(find.text('HE186408'), findsOneWidget);
  });
}

LoginResponse _studentProfile() {
  return LoginResponse.fromJson(<String, dynamic>{
    'id': 12,
    'userName': 'HE186408',
    'firstName': 'Lê Trung',
    'lastName': 'Hiếu',
    'email': 'hieu408@fpt.edu.vn',
    'phone': '0901234567',
    'className': 'SE1911',
    'role': 'STUDENT',
    'roles': <String>['STUDENT'],
    'permissions': <String>[],
    'status': 'ACTIVE',
  });
}

class _FakeProfileService extends ProfileService {
  const _FakeProfileService(this.profile);

  final LoginResponse profile;

  @override
  Future<LoginResponse> fetchCurrentProfile() async => profile;

  @override
  Future<ProfileAcademicSummary> fetchAcademicSummary() async {
    return const ProfileAcademicSummary(
      semesterId: 2,
      semesterName: 'Summer 2026',
      schoolYear: '2025-2026',
      gpa: 8.25,
      gradedSubjects: 4,
      totalCredits: 12,
    );
  }
}
