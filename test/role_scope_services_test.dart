import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/mark_report_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/schedule_service.dart';

void main() {
  group('MarkReportService role endpoints', () {
    test('uses student and parent paths for mark reports', () async {
      final client = _RecordingApiClient(response: <dynamic>[]);
      final service = MarkReportService(client: client);

      await service.fetchMarkReport();
      await service.fetchMarkReport(studentId: 27);

      expect(client.calls, hasLength(2));
      expect(client.calls[0].path, '/student-grades/mark-report');
      expect(client.calls[0].queryParameters, isEmpty);
      expect(client.calls[1].path, '/parent/students/27/mark-report');
      expect(client.calls[1].queryParameters, isEmpty);
    });

    test('uses student and parent paths for mark details', () async {
      final client = _RecordingApiClient(response: _markDetailJson());
      final service = MarkReportService(client: client);

      final studentDetail = await service.fetchMarkDetail(gradeId: 41);
      final childDetail = await service.fetchMarkDetail(
        gradeId: 41,
        studentId: 27,
      );

      expect(studentDetail.id, 41);
      expect(childDetail.subjectCode, 'PRM393');
      expect(client.calls, hasLength(2));
      expect(client.calls[0].path, '/student-grades/41/mark-detail');
      expect(client.calls[1].path, '/parent/students/27/grades/41/mark-detail');
    });
  });

  group('ScheduleService role endpoints', () {
    test('uses student, parent, and teacher day and weekly paths', () async {
      final client = _RecordingApiClient(response: <dynamic>[]);
      final service = ScheduleService(client: client);
      final day = DateTime(2026, 7, 14, 21, 30);
      final weekStart = DateTime(2026, 7, 13, 12);

      await service.fetchScheduleForDate(day);
      await service.fetchScheduleForDate(
        day,
        scope: ScheduleScope.parent,
        studentId: 27,
      );
      await service.fetchScheduleForDate(day, scope: ScheduleScope.teacher);
      await service.fetchWeeklySchedule(weekStart);
      await service.fetchWeeklySchedule(
        weekStart,
        scope: ScheduleScope.parent,
        studentId: 27,
      );
      await service.fetchWeeklySchedule(
        weekStart,
        scope: ScheduleScope.teacher,
      );

      expect(client.calls.map((call) => call.path).toList(), <String>[
        '/schedules/day',
        '/parent/students/27/schedules/day',
        '/teacher/schedules/day',
        '/schedules/weekly',
        '/parent/students/27/schedules/weekly',
        '/teacher/schedules/weekly',
      ]);
      for (final call in client.calls.take(3)) {
        expect(call.queryParameters, <String, Object?>{
          'studyDate': '2026-07-14',
        });
      }
      for (final call in client.calls.skip(3)) {
        expect(call.queryParameters, <String, Object?>{
          'weekStart': '2026-07-13',
        });
      }
    });

    test('parses teacher student count and class names', () async {
      final client = _RecordingApiClient(
        response: <dynamic>[
          <String, dynamic>{
            'id': 18,
            'semesterId': 3,
            'semesterName': 'Summer 2026',
            'subjectId': 5,
            'subjectCode': 'PRM393',
            'subjectName': 'Mobile Programming',
            'studyDate': '2026-07-14',
            'startTime': '07:30:00',
            'endTime': '09:00:00',
            'room': 'BE-301',
            'lecturerName': 'Teacher One',
            'note': null,
            'studentCount': 36,
            'classNames': <dynamic>['SE1911', ' SE1912 ', '', null],
          },
        ],
      );

      final items = await ScheduleService(client: client).fetchScheduleForDate(
        DateTime(2026, 7, 14),
        scope: ScheduleScope.teacher,
      );

      expect(items, hasLength(1));
      expect(items.single.semesterId, 3);
      expect(items.single.subjectId, 5);
      expect(items.single.studentCount, 36);
      expect(items.single.classNames, <String>['SE1911', 'SE1912']);
      expect(items.single.startTime, '07:30');
      expect(client.calls.single.path, '/teacher/schedules/day');
    });

    test('requires studentId for parent day and weekly schedules', () async {
      final client = _RecordingApiClient(response: <dynamic>[]);
      final service = ScheduleService(client: client);
      final date = DateTime(2026, 7, 14);

      await expectLater(
        service.fetchScheduleForDate(date, scope: ScheduleScope.parent),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        service.fetchWeeklySchedule(date, scope: ScheduleScope.parent),
        throwsA(isA<ArgumentError>()),
      );
      expect(client.calls, isEmpty);
    });
  });
}

Map<String, dynamic> _markDetailJson() {
  return <String, dynamic>{
    'id': 41,
    'subjectId': 5,
    'subjectCode': 'PRM393',
    'subjectName': 'Mobile Programming',
    'className': 'SE1911',
    'average': 8.25,
    'letterGrade': 'A',
    'passed': true,
    'items': <dynamic>[],
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
    calls.add(_ApiCall(path, queryParameters));
    return response;
  }
}

class _ApiCall {
  const _ApiCall(this.path, this.queryParameters);

  final String path;
  final Map<String, Object?> queryParameters;
}
