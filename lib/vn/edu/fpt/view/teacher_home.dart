import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/schedule_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/teacher_grades.dart';
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
  static const _orange = Color(0xFFFF8A3D);

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

  void _openGrades() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TeacherGradesScreen()),
    );
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
              loggingOut: _loggingOut,
              onLogout: _logout,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
                children: [
                  const Text(
                    'Không gian giáo viên',
                    style: TextStyle(
                      color: Color(0xFF20334E),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Theo dõi lịch giảng dạy và cập nhật kết quả học tập của sinh viên.',
                    style: TextStyle(color: Color(0xFF68758A), height: 1.45),
                  ),
                  const SizedBox(height: 22),
                  _TeacherFeatureCard(
                    title: 'Lịch dạy',
                    description:
                        'Xem lịch theo ngày, chuyển tuần và theo dõi lớp học.',
                    icon: Icons.calendar_month_outlined,
                    iconColor: const Color(0xFF1976D2),
                    iconBackground: const Color(0xFFE6F2FF),
                    onTap: _openSchedule,
                  ),
                  const SizedBox(height: 14),
                  _TeacherFeatureCard(
                    title: 'Quản lý điểm',
                    description:
                        'Chọn học kỳ, môn được phân công và nhập điểm sinh viên.',
                    icon: Icons.fact_check_outlined,
                    iconColor: _orange,
                    iconBackground: const Color(0xFFFFEFE4),
                    onTap: _openGrades,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE4E8EF)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF21A179),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bạn chỉ có thể xem sinh viên và nhập điểm cho các môn học được nhà trường phân công.',
                            style: TextStyle(
                              color: Color(0xFF56647A),
                              height: 1.45,
                              fontSize: 13,
                            ),
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
        bottomNavigationBar: MainBottomNavigation(onProfile: _openProfile),
      ),
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.displayName,
    required this.userName,
    required this.loggingOut,
    required this.onLogout,
  });

  final String displayName;
  final String userName;
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
                      '$userName · Giáo viên',
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
