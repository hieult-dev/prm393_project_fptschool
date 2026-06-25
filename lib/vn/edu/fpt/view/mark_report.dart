import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/mark_report_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/mark_detail.dart';

class MarkReportScreen extends StatefulWidget {
  const MarkReportScreen({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<MarkReportScreen> createState() => _MarkReportScreenState();
}

class _MarkReportScreenState extends State<MarkReportScreen> {
  static const _background = Color(0xFFF4F4F5);
  static const _topColor = Color(0xFF183455);
  static const _bottomColor = Color(0xFF183455);
  static const _orange = Color(0xFFFF9800);
  static const _green = Color(0xFF16C79A);
  static const _red = Color(0xFFFF3D45);
  static const _mutedText = Color(0xFF747B8F);
  static const _titleText = Color(0xFF1C3154);

  late final Future<List<MarkReportSemester>> _markReportFuture;
  int? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _markReportFuture = MarkReportService().fetchMarkReport(
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _topColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bottomColor,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Container(
                color: _topColor,
                child: SafeArea(
                  bottom: false,
                  child: _buildHeader(context),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MarkReportSemester>>(
                future: _markReportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _orange,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildStateMessage(
                      icon: Icons.error_outline,
                      title: 'Cannot load mark report',
                      message: _cleanError(snapshot.error),
                    );
                  }

                  final semesters = snapshot.data ?? <MarkReportSemester>[];
                  if (semesters.isEmpty) {
                    return _buildStateMessage(
                      icon: Icons.school_outlined,
                      title: 'No mark report',
                      message: 'There are no semesters to display.',
                    );
                  }

                  final selectedSemester = _selectedSemester(semesters);
                  return Column(
                    children: [
                      _buildSemesterTabs(semesters, selectedSemester.id),
                      Expanded(
                        child: selectedSemester.grades.isEmpty
                            ? _buildStateMessage(
                                icon: Icons.bar_chart_outlined,
                                title: 'No grades',
                                message: 'This semester has no grade data yet.',
                              )
                            : _buildGradeList(selectedSemester.grades),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.only(left: 2, right: 10),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.chevron_left,
                size: 32,
              ),
              label: const Text(
                'Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Mark Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterTabs(
    List<MarkReportSemester> semesters,
    int selectedSemesterId,
  ) {
    return Container(
      height: 66,
      color: _background,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final semester in semesters) ...[
              _SemesterChip(
                label: semester.shortName,
                icon: _semesterIcon(semester.name),
                selected: semester.id == selectedSemesterId,
                onTap: () {
                  setState(() {
                    _selectedSemesterId = semester.id;
                  });
                },
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGradeList(List<MarkReportGrade> grades) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
      itemBuilder: (context, index) {
        final grade = grades[index];
        return _GradeCard(
          grade: grade,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarkDetailScreen(gradeId: grade.id),
              ),
            );
          },
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemCount: grades.length,
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF98A2B3),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _titleText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedText,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: _bottomColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              width: 50,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3F4652),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.home_filled,
                color: _orange,
                size: 28,
              ),
            ),
            const Icon(
              Icons.chat_bubble,
              color: Color(0xFF9EACBE),
              size: 25,
            ),
            const Icon(
              Icons.person,
              color: Color(0xFF9EACBE),
              size: 27,
            ),
          ],
        ),
      ),
    );
  }

  MarkReportSemester _selectedSemester(List<MarkReportSemester> semesters) {
    final selectedId = _selectedSemesterId;
    if (selectedId != null) {
      for (final semester in semesters) {
        if (semester.id == selectedId) {
          return semester;
        }
      }
    }

    final now = DateTime.now();
    for (final semester in semesters) {
      if (semester.contains(now)) {
        return semester;
      }
    }

    for (final semester in semesters) {
      if (semester.grades.isNotEmpty) {
        return semester;
      }
    }

    return semesters.first;
  }

  IconData _semesterIcon(String semesterName) {
    final name = semesterName.toLowerCase();
    if (name.contains('summer')) {
      return Icons.wb_sunny_rounded;
    }
    if (name.contains('spring')) {
      return Icons.local_florist_rounded;
    }
    return Icons.ac_unit_rounded;
  }

  String _cleanError(Object? error) {
    final message = error.toString();
    return message
        .replaceAll(RegExp(r'exception:\s*', caseSensitive: false), '')
        .trim();
  }
}

class _SemesterChip extends StatelessWidget {
  const _SemesterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? _MarkReportScreenState._orange : Colors.white;
    final foreground = selected ? Colors.white : _MarkReportScreenState._titleText;
    final iconBackground = selected
        ? const Color(0x26FFFFFF)
        : const Color(0xFFF1F3F8);
    final iconColor = selected
        ? Colors.white
        : const Color(0xFFB8BEC9);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      elevation: selected ? 4 : 2,
      shadowColor: const Color(0x1A000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 38,
          constraints: const BoxConstraints(minWidth: 136),
          padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.onTap,
  });

  final MarkReportGrade grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = grade.passed
        ? _MarkReportScreenState._green
        : _MarkReportScreenState._red;
    final statusBackground = grade.passed
        ? const Color(0xFFE1FAF0)
        : const Color(0xFFFFE2E7);
    final statusText = grade.passed ? 'Passed' : 'Not Passed';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 102),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 4,
                  color: statusColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 14, 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: const TextStyle(
                                color: _MarkReportScreenState._mutedText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text: grade.subjectCode,
                                  style: const TextStyle(
                                    color: _MarkReportScreenState._titleText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: ' - ${grade.subjectName}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 82),
                          height: 21,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEDEFF4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Class name: ${_displayClassName()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _MarkReportScreenState._mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(
                          color: _MarkReportScreenState._mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          const TextSpan(text: 'Average: '),
                          TextSpan(
                            text: grade.average.toStringAsFixed(1),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayClassName() {
    final className = grade.className?.trim();
    if (className == null || className.isEmpty) {
      return 'N/A';
    }
    return className;
  }
}
