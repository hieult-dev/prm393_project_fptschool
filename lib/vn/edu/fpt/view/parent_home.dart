import 'package:flutter/material.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/parent_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/schedule_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/mark_report.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/weekly_timetable.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key, required this.currentUser});

  final LoginResponse currentUser;

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF8A3D);
  static const _background = Color(0xFFF5F7FB);

  final ParentService _parentService = const ParentService();

  List<LinkedStudent> _students = const [];
  Object? _loadError;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  bool _isRedirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _loadError = null;
    });

    try {
      final students = await _parentService.fetchLinkedStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on SessionExpiredException {
      _redirectToLogin();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _clearSession() async {
    try {
      await AuthService().logout();
    } finally {
      await AuthSession.clear();
    }
  }

  void _redirectToLogin() {
    if (_isRedirectingToLogin) return;
    _isRedirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _clearSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut || _isRedirectingToLogin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để tiếp tục xem thông tin của sinh viên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    await _clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Cổng phụ huynh',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _isLoading || _isRefreshing
                ? null
                : () => _loadStudents(refresh: true),
            icon: _isRefreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildParentSummary(),
          Expanded(child: _buildContent()),
        ],
      ),
      bottomNavigationBar: MainBottomNavigation(onProfile: _openProfile),
    );
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  Widget _buildParentSummary() {
    final displayName = widget.currentUser.fullName.trim().isEmpty
        ? widget.currentUser.userName
        : widget.currentUser.fullName.trim();

    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white.withValues(alpha: 0.12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                child: Text(
                  _initials(displayName),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                      'Tài khoản phụ huynh · ${widget.currentUser.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _loadError == null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${_students.length} con',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _orange));
    }

    if (_loadError != null) {
      return _refreshableState(
        icon: Icons.cloud_off_rounded,
        title: 'Không thể tải danh sách',
        message: _errorMessage(_loadError),
        actionLabel: 'Thử lại',
        onAction: _loadStudents,
      );
    }

    if (_students.isEmpty) {
      return _refreshableState(
        icon: Icons.family_restroom_rounded,
        title: 'Chưa có sinh viên liên kết',
        message:
            'Tài khoản của bạn chưa được liên kết với sinh viên nào. '
            'Vui lòng liên hệ nhà trường để được hỗ trợ.',
        actionLabel: 'Làm mới',
        onAction: () => _loadStudents(refresh: true),
      );
    }

    return RefreshIndicator(
      color: _orange,
      onRefresh: () => _loadStudents(refresh: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        itemCount: _students.length + 1,
        separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 14 : 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinh viên đã liên kết',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Chọn điểm hoặc lịch học để xem thông tin của từng sinh viên.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.35,
                  ),
                ),
              ],
            );
          }
          return _StudentCard(
            student: _students[index - 1],
            onOpenGrades: () => _openGrades(_students[index - 1]),
            onOpenSchedule: () => _openSchedule(_students[index - 1]),
          );
        },
      ),
    );
  }

  Widget _refreshableState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        color: _orange,
        onRefresh: () => _loadStudents(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight > 48
                    ? constraints.maxHeight - 48
                    : 0,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EEF6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(icon, color: _navy, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(actionLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        minimumSize: const Size(150, 48),
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

  void _openGrades(LinkedStudent student) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MarkReportScreen(
          studentId: student.id,
          studentName: _studentName(student),
        ),
      ),
    );
  }

  void _openSchedule(LinkedStudent student) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WeeklyTimetableScreen(
          scope: ScheduleScope.parent,
          studentId: student.id,
          studentName: _studentName(student),
        ),
      ),
    );
  }

  String _studentName(LinkedStudent student) {
    final fullName = student.fullName.trim();
    return fullName.isEmpty ? student.userName : fullName;
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'PH';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _errorMessage(Object? error) {
    if (error is FormatException) {
      return 'Dữ liệu từ máy chủ không đúng định dạng. Vui lòng thử lại.';
    }
    final message = error
        .toString()
        .replaceFirst(
          RegExp(r'^(exception|error):\s*', caseSensitive: false),
          '',
        )
        .trim();
    return message.isEmpty
        ? 'Đã xảy ra lỗi. Vui lòng kiểm tra kết nối và thử lại.'
        : message;
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onOpenGrades,
    required this.onOpenSchedule,
  });

  final LinkedStudent student;
  final VoidCallback onOpenGrades;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final fullName = student.fullName.trim().isEmpty
        ? student.userName
        : student.fullName.trim();
    final className = student.className?.trim();
    final isActive = student.status.toUpperCase() == 'ACTIVE';

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE4E9F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFFFE8D7),
                  foregroundColor: _ParentHomeScreenState._orange,
                  child: const Icon(Icons.school_rounded, size: 27),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ParentHomeScreenState._navy,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        [
                          student.userName,
                          if (className != null && className.isNotEmpty)
                            className,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F8F1)
                        : const Color(0xFFFFECEC),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isActive ? 'Tài khoản hoạt động' : 'Tài khoản khóa',
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF157A55)
                          : const Color(0xFFB42318),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onOpenGrades,
                    icon: const Icon(Icons.bar_chart_rounded, size: 20),
                    label: const Text('Xem điểm'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: _ParentHomeScreenState._navy,
                      backgroundColor: const Color(0xFFE8EEF7),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenSchedule,
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    label: const Text('Lịch học'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: _ParentHomeScreenState._navy,
                      side: const BorderSide(color: Color(0xFFB8C5D8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
