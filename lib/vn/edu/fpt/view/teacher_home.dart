import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/schedule_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/events_feed_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/teacher_applications.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/weekly_timetable.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key, required this.currentUser});

  final LoginResponse currentUser;

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  static const _navy = Color(0xFF183A66);
  static const _canvas = Color(0xFFF4F6FA);

  var _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _openSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const WeeklyTimetableScreen(scope: ScheduleScope.teacher),
      ),
    );
  }

  void _openApplications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TeacherApplicationsScreen(),
      ),
    );
  }

  void _openEvents() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const EventsFeedScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final fullName = widget.currentUser.fullName.trim();
    final displayName = fullName.isEmpty
        ? widget.currentUser.userName
        : fullName;
    final teacherTitle = _teacherTitle(widget.currentUser);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _canvas,
        body: Column(
          children: [
            _TeacherHeader(
              displayName: displayName,
              userName: widget.currentUser.userName,
              teacherTitle: teacherTitle,
              loggingOut: _loggingOut,
              onLogout: _logout,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                children: [
                  _TeacherFeatureCard(
                    title: 'Lịch dạy',
                    description:
                        'Xem lịch theo ngày, chuyển tuần và theo dõi lớp học.',
                    icon: Icons.calendar_month_outlined,
                    iconColor: const Color(0xFF1976D2),
                    iconBackground: const Color(0xFFE6F2FF),
                    onTap: _openSchedule,
                  ),
                  if (widget.currentUser.hasRole('HOMEROOM_TEACHER')) ...[
                    const SizedBox(height: 14),
                    _TeacherFeatureCard(
                      title: 'Đơn phụ huynh',
                      description:
                          'Nhận đơn của lớp chủ nhiệm, duyệt hoặc từ chối kèm phản hồi.',
                      icon: Icons.mark_email_unread_outlined,
                      iconColor: const Color(0xFF21A179),
                      iconBackground: const Color(0xFFE4F8EF),
                      onTap: _openApplications,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigation(
          onEvents: _openEvents,
          onProfile: _openProfile,
        ),
      ),
    );
  }

  String _teacherTitle(LoginResponse user) {
    final backendTitle = user.teacherTitle?.trim();
    if (backendTitle != null && backendTitle.isNotEmpty) {
      return backendTitle;
    }
    if (user.hasRole('HOMEROOM_TEACHER')) {
      final className = user.className?.trim();
      return className == null || className.isEmpty
          ? 'Giáo viên chủ nhiệm'
          : 'Giáo viên chủ nhiệm · $className';
    }
    if (user.hasRole('SUBJECT_TEACHER') || user.hasRole('TEACHER')) {
      return 'Giáo viên bộ môn';
    }
    return 'Giáo viên';
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.displayName,
    required this.userName,
    required this.teacherTitle,
    required this.loggingOut,
    required this.onLogout,
  });

  final String displayName;
  final String userName;
  final String teacherTitle;
  final bool loggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _TeacherHomeScreenState._navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB066),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
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
                      '$userName · $teacherTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB9C9E0),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: loggingOut ? null : onLogout,
                tooltip: 'Đăng xuất',
                icon: loggingOut
                    ? const SizedBox.square(
                        dimension: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherFeatureCard extends StatelessWidget {
  const _TeacherFeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E7EE)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: iconColor, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF243650),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF6A7688),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF8A96A8)),
            ],
          ),
        ),
      ),
    );
  }
}
