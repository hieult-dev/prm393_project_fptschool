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
      expect(response.roles, ['STUDENT']);
      expect(response.permissions, isEmpty);
      expect(response.primaryRole, 'STUDENT');
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
      expect(response.roles, ['STUDENT']);
      expect(response.status, '');
    });

    test('routes a migrated lecturer by the TEACHER role list', () {
      final response = LoginResponse.fromJson({
        'id': 3,
        'userName': 'lecturer01',
        'firstName': 'Giảng viên',
        'lastName': 'Một',
        'email': 'lecturer01@example.com',
        'role': 'LECTURER',
        'roles': ['LECTURER', 'TEACHER'],
        'permissions': ['GRADE_READ', 'GRADE_WRITE'],
        'teacherTitle': 'Giáo viên bộ môn',
        'status': 'ACTIVE',
      });

      expect(response.role, 'LECTURER');
      expect(response.hasRole('teacher'), isTrue);
      expect(response.primaryRole, 'TEACHER');
      expect(response.teacherTitle, 'Giáo viên bộ môn');
      expect(response.permissions, ['GRADE_READ', 'GRADE_WRITE']);
    });

    test('recognizes a parent account', () {
      final response = LoginResponse.fromJson({
        'id': 4,
        'userName': 'parent01',
        'firstName': 'Phụ huynh',
        'lastName': 'Một',
        'roles': ['PARENT'],
        'permissions': ['CHILD_READ'],
        'status': 'ACTIVE',
      });

      expect(response.primaryRole, 'PARENT');
      expect(response.studentCode, 'parent01');
      expect(response.fullName, 'Phụ huynh Một');
    });
  });
}
