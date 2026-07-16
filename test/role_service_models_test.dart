import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/attendance_report_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/club_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/exam_schedule_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/parent_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/profile_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/student_application_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/teacher_service.dart';

void main() {
  group('School role models', () {
    test('parses linked students, semesters, and subjects', () {
      final student = LinkedStudent.fromJson(<String, dynamic>{
        'id': 12,
        'userName': 'SE0012',
        'fullName': 'Nguyen Van An',
        'email': 'an@example.com',
        'className': 'SE1911',
        'status': 'ACTIVE',
      });
      final semester = SchoolSemester.fromJson(<String, dynamic>{
        'id': 3,
        'name': 'Summer 2026',
        'schoolYear': '2025-2026',
        'startDate': '2026-05-04',
        'endDate': '2026-08-16',
      });
      final subject = SchoolSubject.fromJson(<String, dynamic>{
        'id': 5,
        'subjectCode': 'PRM393',
        'subjectName': 'Mobile Programming',
        'credits': 3,
      });

      expect(student.id, 12);
      expect(student.className, 'SE1911');
      expect(semester.startDate, DateTime(2026, 5, 4));
      expect(semester.displayName, 'Summer 2026 - 2025-2026');
      expect(subject.subjectCode, 'PRM393');
      expect(subject.credits, 3);
    });

    test('parses application types and student applications', () {
      final type = ApplicationType.fromJson(<String, dynamic>{
        'id': 1,
        'name': 'Leave request',
        'description': 'Request leave from class',
      });
      final application = StudentApplication.fromJson(<String, dynamic>{
        'id': 10,
        'userId': 12,
        'applicationTypeId': 1,
        'title': 'Xin nghỉ học',
        'content': 'Em xin nghỉ học buổi PRM393.',
        'status': 'PENDING',
        'studentCode': 'HE186408',
        'studentName': 'Lê Trung Hiếu',
        'className': 'SE1911',
        'applicationTypeName': 'Leave request',
        'responseNote': null,
        'createdAt': '2026-07-15T08:30:00',
      });

      expect(type.name, 'Leave request');
      expect(application.applicationTypeId, 1);
      expect(application.status, 'PENDING');
      expect(application.studentName, 'Lê Trung Hiếu');
      expect(application.applicationTypeName, 'Leave request');
      expect(application.createdAt, DateTime(2026, 7, 15, 8, 30));
    });

    test('parses school clubs', () {
      final club = SchoolClub.fromJson(<String, dynamic>{
        'id': 4,
        'name': 'Mobile Dev Club',
        'description': 'Weekly workshops and coding sessions',
        'leaderName': 'Nguyen Mentor',
        'contactEmail': 'mobile.club@fpt.edu.vn',
        'imageUrl': null,
        'status': 'ACTIVE',
        'createdAt': '2026-07-16T08:00:00',
      });

      expect(club.id, 4);
      expect(club.name, 'Mobile Dev Club');
      expect(club.leaderName, 'Nguyen Mentor');
      expect(club.contactEmail, 'mobile.club@fpt.edu.vn');
      expect(club.createdAt, DateTime(2026, 7, 16, 8));
    });

    test('parses exam schedule items', () {
      final exam = ExamScheduleItem.fromJson(<String, dynamic>{
        'id': 31,
        'semesterId': 2,
        'semesterName': 'Summer 2026',
        'subjectId': 1,
        'subjectCode': 'PRM393',
        'subjectName': 'Mobile Programming',
        'examType': 'FINAL',
        'examDate': '2026-08-10',
        'startTime': '07:30:00',
        'endTime': '09:00:00',
        'room': 'BE-301',
        'seatNumber': 'S01',
        'proctorName': 'Nguyen Van A',
        'note': 'Bring student card',
        'status': 'PUBLISHED',
      });

      expect(exam.subjectCode, 'PRM393');
      expect(exam.examDate, DateTime(2026, 8, 10));
      expect(exam.startTime, '07:30:00');
      expect(exam.seatNumber, 'S01');
      expect(exam.status, 'PUBLISHED');
    });

    test('parses attendance report semesters', () {
      final semester = AttendanceReportSemester.fromJson(<String, dynamic>{
        'id': 2,
        'name': 'Summer 2026',
        'schoolYear': '2025-2026',
        'startDate': '2026-05-04',
        'endDate': '2026-08-22',
        'reports': <Map<String, dynamic>>[
          <String, dynamic>{
            'subjectId': 1,
            'subjectCode': 'PRM393',
            'subjectName': 'Mobile Programming',
            'className': 'SE1911-JV',
            'startDate': '2026-05-12',
            'endDate': '2026-08-20',
            'attendedSessions': 14,
            'totalSessions': 17,
            'absentSessions': 3,
            'attendancePercentage': 82,
          },
        ],
      });

      expect(semester.tabLabel, 'SUMMER2026');
      expect(semester.reports.single.subjectCode, 'PRM393');
      expect(semester.reports.single.className, 'SE1911-JV');
      expect(semester.reports.single.attendancePercentage, 82);
    });

    test('parses teacher grade and serializes input items without ids', () {
      final grade = TeacherGrade.fromJson(_gradeJson());

      expect(grade.id, 41);
      expect(grade.userId, 12);
      expect(grade.totalScore, 8.25);
      expect(grade.items, hasLength(2));
      expect(grade.items.first.id, 101);
      expect(grade.items.first.toRequestJson(), <String, dynamic>{
        'name': 'Progress Test',
        'weight': 40.0,
        'score': 8.0,
      });
    });
  });

  group('Role services', () {
    test('profile service requests and parses the current user', () async {
      final client = _RecordingApiClient(
        response: <String, dynamic>{
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
        },
      );

      final profile = await ProfileService(
        client: client,
      ).fetchCurrentProfile();

      expect(profile.userName, 'HE186408');
      expect(profile.fullName, 'Lê Trung Hiếu');
      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/profile');
    });

    test('profile service parses the current semester and GPA', () async {
      final client = _RecordingApiClient(
        response: <String, dynamic>{
          'semesterId': 2,
          'semesterName': 'Summer 2026',
          'schoolYear': '2025-2026',
          'gpa': 8.25,
          'gradedSubjects': 4,
          'totalCredits': 12,
        },
      );

      final summary = await ProfileService(
        client: client,
      ).fetchAcademicSummary();

      expect(summary.semesterName, 'Summer 2026');
      expect(summary.schoolYear, '2025-2026');
      expect(summary.gpa, 8.25);
      expect(summary.totalCredits, 12);
      expect(client.calls.single.path, '/profile/academic-summary');
    });

    test('parent service requests and parses linked students', () async {
      final client = _RecordingApiClient(
        response: <dynamic>[
          <String, dynamic>{
            'id': 12,
            'userName': 'SE0012',
            'fullName': 'Nguyen Van An',
            'email': null,
            'className': 'SE1911',
            'status': 'ACTIVE',
          },
        ],
      );

      final students = await ParentService(
        client: client,
      ).fetchLinkedStudents();

      expect(students.single.userName, 'SE0012');
      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/parent/students');
    });

    test('teacher lookup methods send supported filters', () async {
      final client = _RecordingApiClient(response: <dynamic>[]);
      final service = TeacherService(client: client);

      await service.fetchSemesters();
      await service.fetchSubjects(semesterId: 3);
      await service.fetchStudents(
        subjectId: 5,
        semesterId: 3,
        search: '  SE0012  ',
      );
      await service.fetchGrades(userId: 12, semesterId: 3, subjectId: 5);

      expect(client.calls[0].path, '/teacher/semesters');
      expect(client.calls[1].queryParameters, <String, Object?>{
        'semesterId': 3,
      });
      expect(client.calls[2].queryParameters, <String, Object?>{
        'subjectId': 5,
        'semesterId': 3,
        'search': 'SE0012',
      });
      expect(client.calls[3].queryParameters, <String, Object?>{
        'userId': 12,
        'semesterId': 3,
        'subjectId': 5,
      });
    });

    test('teacher create and update send the backend grade payload', () async {
      final client = _RecordingApiClient(response: _gradeJson());
      final service = TeacherService(client: client);
      const items = <TeacherGradeItem>[
        TeacherGradeItem(name: 'Progress Test', weight: 40, score: 8),
        TeacherGradeItem(name: 'Final Exam', weight: 60, score: 8.5),
      ];

      await service.createGrade(
        userId: 12,
        subjectId: 5,
        semesterId: 3,
        items: items,
      );
      await service.updateGrade(
        gradeId: 41,
        userId: 12,
        subjectId: 5,
        semesterId: 3,
        items: items,
      );
      await service.deleteGrade(41);

      final expectedBody = <String, dynamic>{
        'userId': 12,
        'subjectId': 5,
        'semesterId': 3,
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'Progress Test',
            'weight': 40.0,
            'score': 8.0,
          },
          <String, dynamic>{'name': 'Final Exam', 'weight': 60.0, 'score': 8.5},
        ],
      };
      expect(client.calls[0].method, 'POST');
      expect(client.calls[0].path, '/teacher/grades');
      expect(client.calls[0].body, expectedBody);
      expect(client.calls[1].method, 'PUT');
      expect(client.calls[1].path, '/teacher/grades/41');
      expect(client.calls[1].body, expectedBody);
      expect(client.calls[2].method, 'DELETE');
      expect(client.calls[2].path, '/teacher/grades/41');
    });

    test(
      'student application service requests list, types and create payload',
      () async {
        final client = _RecordingApiClient(response: <dynamic>[]);
        final service = StudentApplicationService(client: client);

        await service.fetchApplicationTypes();
        await service.fetchApplications(studentId: 12, status: 'PENDING');
        await service.fetchTeacherApplications(status: 'APPROVED');

        client.response = <String, dynamic>{
          'id': 10,
          'userId': 12,
          'applicationTypeId': 1,
          'title': 'Xin nghỉ học',
          'content': 'Em xin nghỉ học buổi PRM393.',
          'status': 'PENDING',
        };
        await service.createApplication(
          studentId: 12,
          applicationTypeId: 1,
          title: ' Xin nghỉ học ',
          content: ' Em xin nghỉ học buổi PRM393. ',
        );
        await service.reviewTeacherApplication(
          applicationId: 10,
          status: ' approved ',
          responseNote: ' Đồng ý cho nghỉ. ',
        );

        expect(client.calls[0].path, '/application-types');
        expect(client.calls[1].path, '/parent/students/12/applications');
        expect(client.calls[1].queryParameters, <String, Object?>{
          'status': 'PENDING',
        });
        expect(client.calls[2].path, '/teacher/applications');
        expect(client.calls[2].queryParameters, <String, Object?>{
          'status': 'APPROVED',
        });
        expect(client.calls[3].path, '/parent/students/12/applications');
        expect(client.calls[3].body, <String, dynamic>{
          'applicationTypeId': 1,
          'title': 'Xin nghỉ học',
          'content': 'Em xin nghỉ học buổi PRM393.',
        });
        expect(client.calls[4].method, 'PATCH');
        expect(client.calls[4].path, '/teacher/applications/10/review');
        expect(client.calls[4].body, <String, dynamic>{
          'status': 'APPROVED',
          'responseNote': 'Đồng ý cho nghỉ.',
        });
      },
    );

    test('club service requests active clubs', () async {
      final client = _RecordingApiClient(
        response: <dynamic>[
          <String, dynamic>{
            'id': 4,
            'name': 'Mobile Dev Club',
            'status': 'ACTIVE',
          },
        ],
      );

      final clubs = await ClubService(client: client).fetchActiveClubs();

      expect(clubs.single.name, 'Mobile Dev Club');
      expect(client.calls.single.method, 'GET');
      expect(client.calls.single.path, '/clubs/search');
      expect(client.calls.single.queryParameters, <String, Object?>{
        'status': 'ACTIVE',
      });
    });

    test(
      'exam schedule service requests the current student schedule',
      () async {
        final client = _RecordingApiClient(
          response: <dynamic>[
            <String, dynamic>{
              'id': 31,
              'semesterId': 2,
              'semesterName': 'Summer 2026',
              'subjectId': 1,
              'subjectCode': 'PRM393',
              'subjectName': 'Mobile Programming',
              'examType': 'FINAL',
              'examDate': '2026-08-10',
              'startTime': '07:30:00',
              'endTime': '09:00:00',
              'status': 'PUBLISHED',
            },
          ],
        );

        final exams = await ExamScheduleService(
          client: client,
        ).fetchMyExamSchedule(semesterId: 2);

        expect(exams.single.subjectCode, 'PRM393');
        expect(client.calls.single.method, 'GET');
        expect(client.calls.single.path, '/exam-schedules/me');
        expect(client.calls.single.queryParameters, <String, Object?>{
          'semesterId': 2,
        });
      },
    );

    test(
      'attendance report service requests the current student report',
      () async {
        final client = _RecordingApiClient(
          response: <dynamic>[
            <String, dynamic>{
              'id': 2,
              'name': 'Summer 2026',
              'schoolYear': '2025-2026',
              'startDate': '2026-05-04',
              'endDate': '2026-08-22',
              'reports': <Map<String, dynamic>>[],
            },
          ],
        );

        final semesters = await AttendanceReportService(
          client: client,
        ).fetchMyAttendanceReport();

        expect(semesters.single.name, 'Summer 2026');
        expect(client.calls.single.method, 'GET');
        expect(client.calls.single.path, '/attendance-reports/me');
      },
    );
  });
}

Map<String, dynamic> _gradeJson() {
  return <String, dynamic>{
    'id': 41,
    'userId': 12,
    'studentCode': 'SE0012',
    'studentName': 'Nguyen Van An',
    'className': 'SE1911',
    'subjectId': 5,
    'subjectCode': 'PRM393',
    'subjectName': 'Mobile Programming',
    'semesterId': 3,
    'semesterName': 'Summer 2026',
    'totalScore': 8.25,
    'letterGrade': 'A',
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 101,
        'name': 'Progress Test',
        'weight': 40,
        'score': 8,
      },
      <String, dynamic>{
        'id': 102,
        'name': 'Final Exam',
        'weight': 60,
        'score': 8.5,
      },
    ],
  };
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({required this.response});

  dynamic response;
  final List<_ApiCall> calls = <_ApiCall>[];

  @override
  Future<dynamic> get(
    String path, {
    Map<String, Object?> queryParameters = const <String, Object?>{},
  }) async {
    calls.add(_ApiCall('GET', path, queryParameters: queryParameters));
    return response;
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    calls.add(_ApiCall('POST', path, body: body));
    return response;
  }

  @override
  Future<dynamic> put(String path, {Object? body}) async {
    calls.add(_ApiCall('PUT', path, body: body));
    return response;
  }

  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    calls.add(_ApiCall('PATCH', path, body: body));
    return response;
  }

  @override
  Future<void> delete(String path) async {
    calls.add(_ApiCall('DELETE', path));
  }
}

class _ApiCall {
  const _ApiCall(
    this.method,
    this.path, {
    this.queryParameters = const <String, Object?>{},
    this.body,
  });

  final String method;
  final String path;
  final Map<String, Object?> queryParameters;
  final Object? body;
}
