import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/attendance_report_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/events_feed_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({
    super.key,
    this.service = const AttendanceReportService(),
  });

  final AttendanceReportService service;

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  static const _navy = Color(0xFF183A66);
  static const _background = Color(0xFFF4F6FA);
  static const _card = Colors.white;
  static const _green = Color(0xFF24D39A);
  static const _orange = Color(0xFFFF9800);
  static const _text = Color(0xFF233752);
  static const _muted = Color(0xFF7C8AA3);

  late Future<List<AttendanceReportSemester>> _reportFuture;
  var _selectedSemesterIndex = 0;

  @override
  void initState() {
    super.initState();
    _reportFuture = widget.service.fetchMyAttendanceReport();
  }

  Future<void> _reload() async {
    final future = widget.service.fetchMyAttendanceReport();
    setState(() => _reportFuture = future);
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
        backgroundColor: _background,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<List<AttendanceReportSemester>>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _green),
                    );
                  }
                  if (snapshot.hasError) {
                    return _AttendanceError(
                      message: _cleanError(snapshot.error),
                      onRetry: _reload,
                    );
                  }

                  final semesters =
                      snapshot.data ?? const <AttendanceReportSemester>[];
                  final selectedIndex =
                      _selectedSemesterIndex >= semesters.length
                      ? 0
                      : _selectedSemesterIndex;
                  return _AttendanceBody(
                    semesters: semesters,
                    selectedIndex: selectedIndex,
                    onSelectSemester: (index) {
                      setState(() => _selectedSemesterIndex = index);
                    },
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
        child: SizedBox(
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.only(left: 4, right: 10),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.chevron_left_rounded, size: 32),
                  label: const Text(
                    'Home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Text(
                'Attendance Report',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Positioned(
                right: 12,
                child: IconButton(
                  onPressed: _reload,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
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

class _AttendanceBody extends StatelessWidget {
  const _AttendanceBody({
    required this.semesters,
    required this.selectedIndex,
    required this.onSelectSemester,
    required this.onRefresh,
  });

  final List<AttendanceReportSemester> semesters;
  final int selectedIndex;
  final ValueChanged<int> onSelectSemester;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (semesters.isEmpty) {
      return RefreshIndicator(
        color: _AttendanceReportScreenState._green,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
          children: const [_AttendanceEmptyState()],
        ),
      );
    }

    final selectedSemester = semesters[selectedIndex];
    return Column(
      children: [
        _SemesterTabs(
          semesters: semesters,
          selectedIndex: selectedIndex,
          onSelect: onSelectSemester,
        ),
        Expanded(
          child: RefreshIndicator(
            color: _AttendanceReportScreenState._green,
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 110),
              children: selectedSemester.reports.isEmpty
                  ? const [_AttendanceEmptyState()]
                  : selectedSemester.reports
                        .map(
                          (report) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AttendanceCard(report: report),
                          ),
                        )
                        .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _SemesterTabs extends StatelessWidget {
  const _SemesterTabs({
    required this.semesters,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AttendanceReportSemester> semesters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        itemBuilder: (context, index) {
          final semester = semesters[index];
          final selected = selectedIndex == index;
          return _SemesterTab(
            label: semester.tabLabel,
            selected: selected,
            onTap: () => onSelect(index),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemCount: semesters.length,
      ),
    );
  }
}

class _SemesterTab extends StatelessWidget {
  const _SemesterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _AttendanceReportScreenState._orange : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          constraints: const BoxConstraints(minWidth: 136),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE6ECF5),
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x22FF9800),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: .18)
                      : const Color(0xFFF0F3F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_florist_rounded,
                  color: selected
                      ? const Color(0xFFFFD29A)
                      : const Color(0xFFB7C0CD),
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _AttendanceReportScreenState._card,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.report});

  final AttendanceReportItem report;

  @override
  Widget build(BuildContext context) {
    final accent = report.attendancePercentage >= 85
        ? _AttendanceReportScreenState._green
        : _AttendanceReportScreenState._orange;
    return Container(
      decoration: BoxDecoration(
        color: _AttendanceReportScreenState._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
                child: Row(
                  children: [
                    _AttendanceProgress(
                      percentage: report.attendancePercentage,
                      color: accent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.subjectCode} - ${report.subjectName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _AttendanceReportScreenState._text,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _InfoLine('Class name: ${report.className ?? '-'}'),
                          _InfoLine(
                            'Start date: ${_formatDate(report.startDate)}',
                          ),
                          _InfoLine('End date: ${_formatDate(report.endDate)}'),
                          const SizedBox(height: 7),
                          _AttendanceBadge(
                            attended: report.attendedSessions,
                            total: report.totalSessions,
                            color: accent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceProgress extends StatelessWidget {
  const _AttendanceProgress({required this.percentage, required this.color});

  final int percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: percentage.clamp(0, 100) / 100,
              strokeWidth: 9,
              backgroundColor: color.withValues(alpha: .28),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$percentage',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _AttendanceReportScreenState._muted,
        fontSize: 12,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({
    required this.attended,
    required this.total,
    required this.color,
  });

  final int attended;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Attended: $attended/$total',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AttendanceEmptyState extends StatelessWidget {
  const _AttendanceEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 42),
      decoration: BoxDecoration(
        color: _AttendanceReportScreenState._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.fact_check_outlined,
            color: _AttendanceReportScreenState._green,
            size: 52,
          ),
          SizedBox(height: 13),
          Text(
            'No attendance data',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AttendanceReportScreenState._text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Attendance records will appear after class sessions are recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _AttendanceReportScreenState._muted,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceError extends StatelessWidget {
  const _AttendanceError({required this.message, required this.onRetry});

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
              color: _AttendanceReportScreenState._green,
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'Cannot load attendance report',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AttendanceReportScreenState._text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _AttendanceReportScreenState._muted,
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
