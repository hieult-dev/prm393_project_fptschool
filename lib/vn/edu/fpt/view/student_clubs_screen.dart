import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/club_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/events_feed_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class StudentClubsScreen extends StatefulWidget {
  const StudentClubsScreen({super.key, this.service = const ClubService()});

  final ClubService service;

  @override
  State<StudentClubsScreen> createState() => _StudentClubsScreenState();
}

class _StudentClubsScreenState extends State<StudentClubsScreen> {
  static const _navy = Color(0xFF183A66);
  static const _canvas = Color(0xFFF4F6FA);
  static const _orange = Color(0xFFFF8A3D);
  static const _text = Color(0xFF233752);
  static const _muted = Color(0xFF7C8AA3);

  late Future<List<SchoolClub>> _clubsFuture;
  var _search = '';

  @override
  void initState() {
    super.initState();
    _clubsFuture = widget.service.fetchActiveClubs();
  }

  Future<void> _reload() async {
    final future = widget.service.fetchActiveClubs();
    setState(() => _clubsFuture = future);
    await future;
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
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

  void _openClub(SchoolClub club) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClubDetailScreen(club: club)),
    );
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
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<SchoolClub>>(
                future: _clubsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _ClubsLoading();
                  }
                  if (snapshot.hasError) {
                    return _ClubsError(
                      message: _cleanError(snapshot.error),
                      onRetry: _reload,
                    );
                  }

                  final clubs = snapshot.data ?? const <SchoolClub>[];
                  final filteredClubs = _filterClubs(clubs);
                  return RefreshIndicator(
                    color: _orange,
                    onRefresh: _reload,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                      children: [
                        _ClubSearchField(
                          value: _search,
                          onChanged: (value) => setState(() => _search = value),
                        ),
                        const SizedBox(height: 15),
                        _ClubOverview(
                          total: clubs.length,
                          visible: filteredClubs.length,
                        ),
                        const SizedBox(height: 15),
                        if (clubs.isEmpty)
                          const _ClubsEmpty()
                        else if (filteredClubs.isEmpty)
                          const _ClubsNoSearchResult()
                        else
                          ...filteredClubs.map(
                            (club) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ClubCard(
                                club: club,
                                onTap: () => _openClub(club),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigation(
          onHome: _goHome,
          onEvents: _openEvents,
          onProfile: _openProfile,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clubs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Student clubs and activities',
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

  List<SchoolClub> _filterClubs(List<SchoolClub> clubs) {
    final keyword = _search.trim().toLowerCase();
    if (keyword.isEmpty) return clubs;
    return clubs
        .where((club) {
          return [
            club.name,
            club.description,
            club.leaderName,
            club.contactEmail,
          ].whereType<String>().any(
            (value) => value.toLowerCase().contains(keyword),
          );
        })
        .toList(growable: false);
  }

  String _cleanError(Object? error) {
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '');
  }
}

class ClubDetailScreen extends StatelessWidget {
  const ClubDetailScreen({super.key, required this.club});

  final SchoolClub club;

  static const _navy = _StudentClubsScreenState._navy;
  static const _canvas = _StudentClubsScreenState._canvas;
  static const _orange = _StudentClubsScreenState._orange;
  static const _text = _StudentClubsScreenState._text;
  static const _muted = _StudentClubsScreenState._muted;

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  _ClubHero(club: club),
                  const SizedBox(height: 14),
                  _ClubSection(
                    title: 'Club information',
                    child: Column(
                      children: [
                        if (club.leaderName != null)
                          _ClubDetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Leader',
                            value: club.leaderName!,
                          ),
                        if (club.contactEmail != null)
                          _ClubDetailRow(
                            icon: Icons.mail_outline_rounded,
                            label: 'Email',
                            value: club.contactEmail!,
                          ),
                        _ClubDetailRow(
                          icon: Icons.verified_rounded,
                          label: 'Status',
                          value: club.status.isEmpty
                              ? 'ACTIVE'
                              : club.status.toUpperCase(),
                          valueColor: _orange,
                        ),
                        if (club.createdAt != null)
                          _ClubDetailRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Created date',
                            value: _formatDate(club.createdAt!),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ClubSection(
                    title: 'About',
                    child: Text(
                      club.description ?? 'No introduction content yet.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (club.contactEmail != null) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _showContactDialog(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text('Contact club'),
                    ),
                  ],
                ],
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
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.chevron_left_rounded),
                color: Colors.white,
                iconSize: 34,
                tooltip: 'Back',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Club details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB8C8E6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  void _showContactDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mail_outline_rounded),
        title: Text(club.name),
        content: Text(club.contactEmail ?? ''),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _ClubSearchField extends StatefulWidget {
  const _ClubSearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_ClubSearchField> createState() => _ClubSearchFieldState();
}

class _ClubSearchFieldState extends State<_ClubSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ClubSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search club, leader, or email',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6ECF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6ECF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _StudentClubsScreenState._orange),
        ),
      ),
    );
  }
}

class _ClubOverview extends StatelessWidget {
  const _ClubOverview({required this.total, required this.visible});

  final int total;
  final int visible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF2C6FB0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visible/$total clubs',
                  style: const TextStyle(
                    color: _StudentClubsScreenState._text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Danh sách đang hoạt động',
                  style: TextStyle(
                    color: _StudentClubsScreenState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club, required this.onTap});

  final SchoolClub club;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE6ECF5)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClubVisual(club: club),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              club.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _StudentClubsScreenState._text,
                                fontSize: 17,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _StudentClubsScreenState._muted,
                            size: 24,
                          ),
                        ],
                      ),
                      if (club.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          club.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _StudentClubsScreenState._muted,
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 13),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (club.leaderName != null)
                            _ClubChip(
                              icon: Icons.person_outline_rounded,
                              label: club.leaderName!,
                            ),
                          if (club.contactEmail != null)
                            _ClubChip(
                              icon: Icons.mail_outline_rounded,
                              label: club.contactEmail!,
                            ),
                          _ClubChip(
                            icon: Icons.verified_rounded,
                            label: club.status.isEmpty ? 'ACTIVE' : club.status,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClubVisual extends StatelessWidget {
  const _ClubVisual({required this.club});

  final SchoolClub club;

  @override
  Widget build(BuildContext context) {
    final imageUrl = club.imageUrl;
    if (imageUrl != null) {
      return AspectRatio(
        aspectRatio: 16 / 7,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _ClubBanner(club: club),
        ),
      );
    }
    return _ClubBanner(club: club);
  }
}

class _ClubBanner extends StatelessWidget {
  const _ClubBanner({required this.club});

  final SchoolClub club;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF18A8E8), Color(0xFF22C7A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -28,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.17),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: _colorForClub(club.id),
                    size: 34,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        club.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        club.leaderName ?? 'FPT Schools club',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFEAFDFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }
}

class _ClubHero extends StatelessWidget {
  const _ClubHero({required this.club});

  final SchoolClub club;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClubVisual(club: club),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club.name,
                  style: const TextStyle(
                    color: ClubDetailScreen._text,
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (club.leaderName != null)
                      _ClubChip(
                        icon: Icons.person_outline_rounded,
                        label: club.leaderName!,
                      ),
                    if (club.contactEmail != null)
                      _ClubChip(
                        icon: Icons.mail_outline_rounded,
                        label: club.contactEmail!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubSection extends StatelessWidget {
  const _ClubSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ClubDetailScreen._text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _ClubDetailRow extends StatelessWidget {
  const _ClubDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = ClubDetailScreen._text,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ClubDetailScreen._orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ClubDetailScreen._orange, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ClubDetailScreen._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubChip extends StatelessWidget {
  const _ClubChip({required this.icon, required this.label});

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
          Icon(icon, size: 15, color: _StudentClubsScreenState._navy),
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

class _ClubsLoading extends StatelessWidget {
  const _ClubsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _StudentClubsScreenState._orange),
    );
  }
}

class _ClubsError extends StatelessWidget {
  const _ClubsError({required this.message, required this.onRetry});

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
              color: _StudentClubsScreenState._orange,
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'Cannot load clubs',
              style: TextStyle(
                color: _StudentClubsScreenState._text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _StudentClubsScreenState._muted,
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

class _ClubsEmpty extends StatelessWidget {
  const _ClubsEmpty();

  @override
  Widget build(BuildContext context) {
    return const _ClubStateMessage(
      icon: Icons.groups_2_outlined,
      title: 'No clubs yet',
      message: 'Active clubs will appear here.',
    );
  }
}

class _ClubsNoSearchResult extends StatelessWidget {
  const _ClubsNoSearchResult();

  @override
  Widget build(BuildContext context) {
    return const _ClubStateMessage(
      icon: Icons.search_off_rounded,
      title: 'No clubs found',
      message: 'Try another search keyword.',
    );
  }
}

class _ClubStateMessage extends StatelessWidget {
  const _ClubStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9AA8BD), size: 56),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _StudentClubsScreenState._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _StudentClubsScreenState._muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorForClub(int id) {
  const colors = <Color>[
    Color(0xFF18A8E8),
    Color(0xFF22C7A9),
    Color(0xFFFF8A3D),
    Color(0xFF8D5CFF),
  ];
  return colors[id.abs() % colors.length];
}
