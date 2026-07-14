import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/mark_report.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/weekly_timetable.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.currentUser});

  final LoginResponse currentUser;

  static const _background = Color(0xFFF5F6FB);
  static const _topColor = Color(0xFF183A66);
  static const _bottomColor = Color(0xFF183A66);

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
              child: SafeArea(bottom: false, child: _buildHeader()),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                children: [
                  _buildSectionTitle('NOTIFICATION AND APPLICATION STATUS'),
                  const SizedBox(height: 12),
                  _buildStatusSection(),

                  const SizedBox(height: 22),
                  _buildSectionTitle('INFORMATION ACCESS'),
                  const SizedBox(height: 12),
                  _buildInfoAccessSection(context),

                  const SizedBox(height: 22),
                  _buildSectionTitle('REPORTS'),
                  const SizedBox(height: 12),
                  _buildReportSection(context),

                  const SizedBox(height: 22),
                  _buildSectionTitle('OTHERS'),
                  const SizedBox(height: 12),
                  _buildOtherSection(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lê Trung Hiếu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'FPT University',
                  style: TextStyle(
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
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
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

  Widget _buildStatusSection() {
    return Row(
      children: const [
        Expanded(
          child: _HomeCard(
            title: 'Notification',
            icon: Icons.notifications_active,
            iconColor: Color(0xFFFF9800),
            backgroundColor: Color(0xFFFFF3E0),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _HomeCard(
            title: 'Application status',
            icon: Icons.badge,
            iconColor: Color(0xFF1976C9),
            backgroundColor: Color(0xFFEAF2FF),
          ),
        ),
      ],
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: _HomeCard(
                title: 'Semester Schedule',
                icon: Icons.calendar_month,
                iconColor: Color(0xFF8D5CFF),
                backgroundColor: Color(0xFFF0E8FF),
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: SizedBox()),
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
            const Expanded(
              child: _HomeCard(
                title: 'Attendance report',
                icon: Icons.checklist,
                iconColor: Color(0xFF20C997),
                backgroundColor: Color(0xFFE1FAF1),
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
        const SizedBox(height: 10),
        Row(
          children: const [
            Expanded(
              child: _HomeCard(
                title: 'Student Fee',
                icon: Icons.point_of_sale,
                iconColor: Color(0xFFFF4D55),
                backgroundColor: Color(0xFFFFE5EA),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _HomeCard(
                title: 'FPT DNG',
                icon: Icons.payments,
                iconColor: Color(0xFFFF9800),
                backgroundColor: Color(0xFFFFF1DC),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherSection() {
    return Row(
      children: const [
        Expanded(
          child: _HomeCard(
            title: 'Contact',
            icon: Icons.contacts,
            iconColor: Color(0xFF5C6CFF),
            backgroundColor: Color(0xFFEFF2FF),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _HomeCard(
            title: 'Service review',
            icon: Icons.star_border,
            iconColor: Color(0xFFFFB000),
            backgroundColor: Color(0xFFFFF4D8),
          ),
        ),
      ],
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
                color: Color(0xFFFF9800),
                size: 28,
              ),
            ),
            const Icon(Icons.chat_bubble, color: Color(0xFF9EACBE), size: 25),
            const Icon(Icons.person, color: Color(0xFF9EACBE), size: 27),
          ],
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
