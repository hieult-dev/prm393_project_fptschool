import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';

void main() {
  group('LoginResponse.fromJson', () {
    test('parses the current backend response format', () {
      final response = LoginResponse.fromJson({
        'id': 1,
        'userName': '0858111305',
        'firstName': 'Default',
        'lastName': 'User',
        'email': '0858111305@myfschool.local',
        'phone': '0858111305',
        'className': null,
        'role': 'STUDENT',
        'roles': ['STUDENT'],
        'permissions': <String>[],
        'status': 'ACTIVE',
      });

      expect(response.id, 1);
      expect(response.studentCode, '0858111305');
      expect(response.fullName, 'Default User');
      expect(response.email, '0858111305@myfschool.local');
      expect(response.className, isNull);
      expect(response.role, 'STUDENT');
      expect(response.status, 'ACTIVE');
    });

    test('accepts nullable optional backend fields', () {
      final response = LoginResponse.fromJson({
        'id': 2,
        'userName': 'student02',
        'firstName': null,
        'lastName': null,
        'email': null,
        'phone': null,
        'className': null,
        'role': null,
        'roles': ['STUDENT'],
        'status': null,
      });

      expect(response.studentCode, 'student02');
      expect(response.fullName, '');
      expect(response.email, '');
      expect(response.phone, isNull);
      expect(response.className, isNull);
      expect(response.role, 'STUDENT');
      expect(response.status, '');
    });
  });
}
