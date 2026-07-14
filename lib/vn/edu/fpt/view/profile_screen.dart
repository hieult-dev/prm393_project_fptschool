import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/profile_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.service = const ProfileService()});

  final ProfileService service;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF9800);
  static const _canvas = Color(0xFFF3F6FA);
  static const _text = Color(0xFF233752);
  static const _muted = Color(0xFF98A2B3);

  late Future<ProfileOverview> _profileFuture;
  var _showSensitiveInformation = false;
  var _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.service.fetchOverview();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _profileFuture = widget.service.fetchOverview();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _profileFuture = widget.service.fetchOverview();
  }

  Future<void> _reload() async {
    final future = widget.service.fetchOverview();
    setState(() => _profileFuture = future);
    await future;
  }

  void _redirectToLogin() {
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AuthSession.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
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
        body: FutureBuilder<ProfileOverview>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _orange),
              );
            }
            if (snapshot.hasError) {
              if (snapshot.error is SessionExpiredException) {
                _redirectToLogin();
              }
              return _ProfileError(
                message: _errorMessage(snapshot.error),
                onRetry: _reload,
              );
            }
            return _buildProfile(snapshot.requireData);
          },
        ),
        bottomNavigationBar: MainBottomNavigation(
          selectedItem: MainNavigationItem.profile,
          onHome: _goHome,
        ),
      ),
    );
  }

  Widget _buildProfile(ProfileOverview overview) {
    final profile = overview.profile;
    return RefreshIndicator(
      color: _orange,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
            child: Column(
              children: [
                _buildInformationCard(profile),
                const SizedBox(height: 14),
                _buildAcademicCard(overview.academicSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LoginResponse profile) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final displayName = profile.fullName.trim().isEmpty
        ? profile.userName
        : profile.fullName.trim();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 18, 20, 28),
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: -70,
            right: -65,
            child: _DecorativeCircle(size: 180, color: Color(0x102D5B91)),
          ),
          const Positioned(
            bottom: -75,
            left: -75,
            child: _DecorativeCircle(size: 145, color: Color(0x143F4652)),
          ),
          Column(
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: const Color(0xFF344A69),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF72839A), width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFDCE3EC),
                  size: 56,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF007C6D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _roleBadge(profile),
                  style: const TextStyle(
                    color: Color(0xFF35D3B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard(LoginResponse profile) {
    final role = _roleName(profile);
    return _ProfileCard(
      title: 'Thông tin cá nhân',
      accent: _navy,
      child: Column(
        children: [
          _InformationRow(
            icon: Icons.badge_outlined,
            iconColor: _navy,
            iconBackground: const Color(0xFFF0F2F7),
            label: 'Mã tài khoản',
            value: _showSensitiveInformation
                ? profile.userName
                : _maskIdentifier(profile.userName),
            onVisibilityTap: () => setState(
              () => _showSensitiveInformation = !_showSensitiveInformation,
            ),
            informationVisible: _showSensitiveInformation,
          ),
          const SizedBox(height: 15),
          _InformationRow(
            icon: Icons.email_outlined,
            iconColor: _orange,
            iconBackground: const Color(0xFFFFF3E7),
            label: 'Email',
            value: profile.email.trim().isEmpty
                ? 'Chưa cập nhật'
                : _showSensitiveInformation
                ? profile.email
                : _maskEmail(profile.email),
            onVisibilityTap: profile.email.trim().isEmpty
                ? null
                : () => setState(
                    () =>
                        _showSensitiveInformation = !_showSensitiveInformation,
                  ),
            informationVisible: _showSensitiveInformation,
          ),
          if (profile.className?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 15),
            _InformationRow(
              icon: Icons.school_outlined,
              iconColor: const Color(0xFF18A875),
              iconBackground: const Color(0xFFE9FAF4),
              label: 'Lớp',
              value: profile.className!.trim(),
            ),
          ],
          if (profile.phone?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 15),
            _InformationRow(
              icon: Icons.phone_outlined,
              iconColor: const Color(0xFF7B61FF),
              iconBackground: const Color(0xFFF1EEFF),
              label: 'Số điện thoại',
              value: _showSensitiveInformation
                  ? profile.phone!.trim()
                  : _maskIdentifier(profile.phone!.trim()),
            ),
          ],
          const SizedBox(height: 15),
          _InformationRow(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF1A73E8),
            iconBackground: const Color(0xFFEAF3FF),
            label: 'Vai trò',
            value: role,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicCard(ProfileAcademicSummary summary) {
    final semesterName = summary.semesterName?.trim();
    final schoolYear = summary.schoolYear?.trim();
    final hasSemester = semesterName?.isNotEmpty == true;
    final hasGpa = summary.gpa != null;
    return _ProfileCard(
      title: 'Kết quả học tập',
      accent: _orange,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _AcademicMetric(
                icon: Icons.calendar_month_rounded,
                iconColor: _navy,
                iconBackground: const Color(0xFFEAF1FA),
                label: 'Học kỳ hiện tại',
                value: hasSemester ? semesterName! : 'Chưa xác định',
                detail: schoolYear?.isNotEmpty == true
                    ? 'Năm học $schoolYear'
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _AcademicMetric(
                icon: Icons.auto_graph_rounded,
                iconColor: _orange,
                iconBackground: const Color(0xFFFFF3E7),
                label: 'GPA',
                value: hasGpa ? summary.gpa!.toStringAsFixed(2) : '--',
                detail: hasGpa ? 'Thang điểm 10' : 'Chưa có điểm',
                centered: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleBadge(LoginResponse profile) {
    if (profile.hasRole('TEACHER')) return 'GV';
    if (profile.hasRole('PARENT')) return 'PH';
    if (profile.hasRole('STUDENT')) return 'SV';
    return 'TV';
  }

  String _roleName(LoginResponse profile) {
    if (profile.hasRole('TEACHER')) return 'Giáo viên';
    if (profile.hasRole('PARENT')) return 'Phụ huynh';
    if (profile.hasRole('STUDENT')) return 'Sinh viên';
    return profile.primaryRole.isEmpty ? 'Thành viên' : profile.primaryRole;
  }

  String _maskIdentifier(String value) {
    final text = value.trim();
    if (text.length <= 2) return '${text.characters.firstOrNull ?? ''}***';
    if (text.length <= 5) {
      return '${text.substring(0, 1)}***${text.substring(text.length - 1)}';
    }
    final prefixLength = text.length >= 8 ? 3 : 2;
    final suffixLength = text.length >= 8 ? 3 : 2;
    return '${text.substring(0, prefixLength)}***'
        '${text.substring(text.length - suffixLength)}';
  }

  String _maskEmail(String value) {
    final separator = value.indexOf('@');
    if (separator <= 0) return _maskIdentifier(value);
    final local = value.substring(0, separator);
    final domain = value.substring(separator);
    return '${_maskIdentifier(local)}$domain';
  }

  String _errorMessage(Object? error) {
    final message = error?.toString().trim() ?? '';
    if (message.isEmpty) {
      return 'Không thể tải hồ sơ. Vui lòng kiểm tra kết nối và thử lại.';
    }
    return message
        .replaceFirst(
          RegExp(r'^(exception|error):\s*', caseSensitive: false),
          '',
        )
        .trim();
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B183A66),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: _ProfileScreenState._text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.onVisibilityTap,
    this.informationVisible = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final VoidCallback? onVisibilityTap;
  final bool informationVisible;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _ProfileScreenState._muted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ProfileScreenState._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (onVisibilityTap != null)
          IconButton(
            onPressed: onVisibilityTap,
            tooltip: informationVisible ? 'Ẩn thông tin' : 'Hiện thông tin',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              informationVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _ProfileScreenState._muted,
              size: 18,
            ),
          ),
      ],
    );
  }
}

class _AcademicMetric extends StatelessWidget {
  const _AcademicMetric({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.detail,
    this.centered = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String? detail;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 13),
          Text(
            label,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: const TextStyle(
              color: _ProfileScreenState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: _ProfileScreenState._text,
              fontSize: centered ? 28 : 16,
              height: centered ? 1.05 : 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 5),
            Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centered ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                color: _ProfileScreenState._muted,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF98A2B3),
              size: 58,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667085), height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
