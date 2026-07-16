import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/event_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/event_detail_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class EventsFeedScreen extends StatefulWidget {
  const EventsFeedScreen({super.key, this.service = const EventService()});

  final EventService service;

  @override
  State<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends State<EventsFeedScreen> {
  static const _navy = Color(0xFF183A66);
  static const _canvas = Color(0xFFF4F6FA);
  static const _orange = Color(0xFFFF8A3D);
  static const _text = Color(0xFF233752);
  static const _muted = Color(0xFF7C8AA3);

  late Future<List<SchoolEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = widget.service.fetchActiveEvents();
  }

  Future<void> _reload() async {
    final future = widget.service.fetchActiveEvents();
    setState(() => _eventsFuture = future);
    await future;
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }

  void _openEvent(SchoolEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EventDetailScreen(event: event)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Container(
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
                          Icons.event_note_rounded,
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
                              'Sự kiện',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Tin hoạt động mới nhất từ nhà trường',
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
                        tooltip: 'Làm mới',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SchoolEvent>>(
                future: _eventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _EventsLoading();
                  }
                  if (snapshot.hasError) {
                    return _EventsError(
                      message: _cleanError(snapshot.error),
                      onRetry: _reload,
                    );
                  }
                  final events = snapshot.data ?? const <SchoolEvent>[];
                  if (events.isEmpty) {
                    return _EventsEmpty(onRetry: _reload);
                  }
                  return RefreshIndicator(
                    color: _orange,
                    onRefresh: _reload,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _EventCard(
                          event: event,
                          onTap: () => _openEvent(event),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomNavigation(
          selectedItem: MainNavigationItem.events,
          onHome: _goHome,
          onProfile: _openProfile,
        ),
      ),
    );
  }

  String _cleanError(Object? error) {
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '');
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final SchoolEvent event;
  final VoidCallback onTap;

  static const _orange = Color(0xFFFF8A3D);
  static const _text = Color(0xFF233752);
  static const _muted = Color(0xFF7C8AA3);

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
                _EventVisual(event: event),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                color: _text,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: _orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _muted,
                            size: 22,
                          ),
                        ],
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 9),
                        Text(
                          event.description!,
                          style: const TextStyle(
                            color: _muted,
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
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: _formatTimeRange(
                              event.startTime,
                              event.endTime,
                            ),
                          ),
                          if (event.location != null)
                            _InfoChip(
                              icon: Icons.place_outlined,
                              label: event.location!,
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

  static String _formatTimeRange(DateTime start, DateTime? end) {
    final startText = '${_formatDate(start)} · ${_formatClock(start)}';
    if (end == null) return startText;
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    if (sameDay) return '$startText - ${_formatClock(end)}';
    return '$startText - ${_formatDate(end)} · ${_formatClock(end)}';
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  static String _formatClock(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _EventVisual extends StatelessWidget {
  const _EventVisual({required this.event});

  final SchoolEvent event;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl;
    if (imageUrl != null) {
      return AspectRatio(
        aspectRatio: 16 / 7,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _DateBanner(event: event),
        ),
      );
    }
    return _DateBanner(event: event);
  }
}

class _DateBanner extends StatelessWidget {
  const _DateBanner({required this.event});

  final SchoolEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFFFB45F)],
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
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        event.startTime.day.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Color(0xFF233752),
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Tháng ${event.startTime.month}',
                        style: const TextStyle(
                          color: Color(0xFFFF8A3D),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FPT Schools',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Event feed',
                      style: TextStyle(
                        color: Color(0xFFFFF2DF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

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
          Icon(icon, size: 15, color: const Color(0xFF183A66)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
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

class _EventsLoading extends StatelessWidget {
  const _EventsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _EventsFeedScreenState._orange),
    );
  }
}

class _EventsError extends StatelessWidget {
  const _EventsError({required this.message, required this.onRetry});

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
              color: Color(0xFFFF8A3D),
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không tải được sự kiện',
              style: TextStyle(
                color: _EventsFeedScreenState._text,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _EventsFeedScreenState._muted,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
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

class _EventsEmpty extends StatelessWidget {
  const _EventsEmpty({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _EventsFeedScreenState._orange,
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 120, 28, 110),
        children: const [
          Icon(Icons.event_busy_outlined, color: Color(0xFF9AA8BD), size: 56),
          SizedBox(height: 14),
          Text(
            'Chưa có sự kiện',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _EventsFeedScreenState._text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Các sự kiện ACTIVE sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _EventsFeedScreenState._muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
