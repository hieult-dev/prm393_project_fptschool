import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/attendance_report_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/exam_schedule_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/events_feed_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/mark_report.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/parent_home.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/student_clubs_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/teacher_home.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/weekly_timetable.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.currentUser});

  final LoginResponse currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser.hasRole('HOMEROOM_TEACHER') ||
        currentUser.hasRole('SUBJECT_TEACHER') ||
        currentUser.hasRole('TEACHER')) {
      return TeacherHomeScreen(currentUser: currentUser);
    }
    if (currentUser.hasRole('PARENT')) {
      return ParentHomeScreen(currentUser: currentUser);
    }
    if (currentUser.hasRole('STUDENT')) {
      return _StudentHomeScreen(currentUser: currentUser);
    }
    return _UnsupportedRoleScreen(currentUser: currentUser);
  }
}

class _StudentHomeScreen extends StatelessWidget {
  const _StudentHomeScreen({required this.currentUser});

  final LoginResponse currentUser;

  static const _background = Color(0xFFF5F6FB);
  static const _topColor = Color(0xFF183A66);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _topColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            Container(
              color: _topColor,
              child: SafeArea(bottom: false, child: _buildHeader(context)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                children: [
                  _buildSectionTitle('INFORMATION ACCESS'),
                  const SizedBox(height: 12),
                  _buildInfoAccessSection(context),

                  const SizedBox(height: 22),
                  _buildSectionTitle('REPORTS'),
                  const SizedBox(height: 12),
                  _buildReportSection(context),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(context),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 86,
      color: _topColor,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB066),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.fullName.isEmpty
                      ? currentUser.userName
                      : currentUser.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.className == null
                      ? currentUser.userName
                      : '${currentUser.userName} · ${currentUser.className}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8C8E6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _logout(context),
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF183A66),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInfoAccessSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeCard(
                title: 'Weekly timetable',
                icon: Icons.calendar_today,
                iconColor: const Color(0xFF18A8E8),
                backgroundColor: const Color(0xFFE5F6FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WeeklyTimetableScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _HomeCard(
                title: 'Exam schedule',
                icon: Icons.article,
                iconColor: Color(0xFFFF4D55),
                backgroundColor: Color(0xFFFFE5EA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExamScheduleScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _HomeCard(
                title: 'Clubs',
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF20A6C7),
                backgroundColor: const Color(0xFFE4F8FA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentClubsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildReportSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeCard(
                title: 'Attendance report',
                icon: Icons.checklist,
                iconColor: const Color(0xFF20C997),
                backgroundColor: const Color(0xFFE1FAF1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceReportScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HomeCard(
                title: 'Mark Report',
                icon: Icons.bar_chart,
                iconColor: Color(0xFFFFA000),
                backgroundColor: Color(0xFFFFF3C4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MarkReportScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return MainBottomNavigation(
      onEvents: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const EventsFeedScreen())),
      onProfile: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
    );
  }
}

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen({required this.currentUser});

  final LoginResponse currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My FSchool')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.manage_accounts_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'Tài khoản ${currentUser.userName} chưa có vai trò được hỗ trợ trên mobile.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await AuthService().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 122,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF7), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
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
