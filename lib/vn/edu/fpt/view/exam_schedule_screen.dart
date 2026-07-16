import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/exam_schedule_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/events_feed_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({
    super.key,
    this.service = const ExamScheduleService(),
  });

  final ExamScheduleService service;

  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen> {
  static const _navy = Color(0xFF183A66);
  static const _canvas = Color(0xFFF4F6FA);
  static const _orange = Color(0xFFFF8A3D);
  static const _red = Color(0xFFFF4D55);
  static const _text = Color(0xFF233752);
  static const _muted = Color(0xFF7C8AA3);

  late Future<List<ExamScheduleItem>> _examFuture;

  @override
  void initState() {
    super.initState();
    _examFuture = widget.service.fetchMyExamSchedule();
  }

  Future<void> _reload() async {
    final future = widget.service.fetchMyExamSchedule();
    setState(() => _examFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _navy,
      ),
      child: Scaffold(
        backgroundColor: _canvas,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<List<ExamScheduleItem>>(
                future: _examFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _orange),
                    );
                  }
                  if (snapshot.hasError) {
                    return _ExamError(
                      message: _cleanError(snapshot.error),
                      onRetry: _reload,
                    );
                  }
                  return _ExamScheduleList(
                    exams: snapshot.data ?? const <ExamScheduleItem>[],
                    onRefresh: _reload,
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigation(
          onHome: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          onEvents: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EventsFeedScreen()),
          ),
          onProfile: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 18, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.chevron_left_rounded),
                color: Colors.white,
                iconSize: 34,
                tooltip: 'Back',
              ),
              const SizedBox(width: 2),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam schedule',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Student examination timetable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFB8C8E6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _reload,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _cleanError(Object? error) {
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '');
  }
}

class _ExamScheduleList extends StatelessWidget {
  const _ExamScheduleList({required this.exams, required this.onRefresh});

  final List<ExamScheduleItem> exams;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _ExamScheduleScreenState._orange,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          _ExamHeroCard(exams: exams),
          const SizedBox(height: 14),
          if (exams.isEmpty)
            const _ExamEmptyState()
          else
            ...exams.map(
              (exam) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ExamCard(exam: exam),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExamHeroCard extends StatelessWidget {
  const _ExamHeroCard({required this.exams});

  final List<ExamScheduleItem> exams;

  @override
  Widget build(BuildContext context) {
    final nextExam = exams.isEmpty ? null : exams.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B4A), Color(0xFFFFA33C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AFF8A3D),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -36,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: _ExamScheduleScreenState._red,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exams.isEmpty
                          ? 'No exam sessions published'
                          : '${exams.length} exams published',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      nextExam == null
                          ? 'Date, time, room, and subject information will appear here.'
                          : 'Next: ${nextExam.subjectCode} - ${_formatDate(nextExam.examDate)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFFF4EC),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});

  final ExamScheduleItem exam;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExamDateTile(date: exam.examDate),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exam.subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ExamScheduleScreenState._text,
                            fontSize: 16,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ExamStatusChip(status: exam.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${exam.subjectCode} - ${exam.examType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ExamScheduleScreenState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ExamChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${_formatTime(exam.startTime)} - ${_formatTime(exam.endTime)}',
                      ),
                      if (exam.room != null)
                        _ExamChip(
                          icon: Icons.location_on_outlined,
                          label: exam.room!,
                        ),
                      if (exam.seatNumber != null)
                        _ExamChip(
                          icon: Icons.event_seat_outlined,
                          label: exam.seatNumber!,
                        ),
                    ],
                  ),
                  if (exam.proctorName != null || exam.note != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      [
                        if (exam.proctorName != null)
                          'Proctor: ${exam.proctorName}',
                        if (exam.note != null) exam.note,
                      ].join(' - '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ExamScheduleScreenState._muted,
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamDateTile extends StatelessWidget {
  const _ExamDateTile({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date.day.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: _ExamScheduleScreenState._text,
              fontSize: 23,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _monthName(date.month),
            style: const TextStyle(
              color: _ExamScheduleScreenState._orange,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamChip extends StatelessWidget {
  const _ExamChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _ExamScheduleScreenState._navy),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF46566E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamStatusChip extends StatelessWidget {
  const _ExamStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toUpperCase()) {
      'CANCELLED' => const Color(0xFFFF4D55),
      'DRAFT' => const Color(0xFF7C8AA3),
      _ => _ExamScheduleScreenState._orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ExamEmptyState extends StatelessWidget {
  const _ExamEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_late_outlined,
            color: _ExamScheduleScreenState._orange,
            size: 58,
          ),
          SizedBox(height: 14),
          Text(
            'Exam schedule is empty',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ExamScheduleScreenState._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'There are no published exams for this student yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ExamScheduleScreenState._muted,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamError extends StatelessWidget {
  const _ExamError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: _ExamScheduleScreenState._orange,
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'Cannot load exam schedule',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ExamScheduleScreenState._text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ExamScheduleScreenState._muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

String _formatTime(String value) {
  final parts = value.split(':');
  if (parts.length >= 2) {
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
  return value;
}

String _monthName(int month) {
  const names = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (month < 1 || month > 12) return '';
  return names[month - 1];
}
