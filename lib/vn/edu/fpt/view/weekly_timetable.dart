import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/schedule_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/events_feed_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/profile_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/main_bottom_navigation.dart';

class WeeklyTimetableScreen extends StatefulWidget {
  const WeeklyTimetableScreen({
    super.key,
    this.scope = ScheduleScope.student,
    this.studentId,
    this.studentName,
  }) : assert(scope != ScheduleScope.parent || studentId != null);

  final ScheduleScope scope;
  final int? studentId;
  final String? studentName;

  @override
  State<WeeklyTimetableScreen> createState() => _WeeklyTimetableScreenState();
}

class _WeeklyTimetableScreenState extends State<WeeklyTimetableScreen> {
  static const _navy = Color(0xFF19385F);
  static const _canvas = Color(0xFFF8F9FC);
  static const _text = Color(0xFF243651);

  final _service = ScheduleService();
  late DateTime _weekStart;
  late DateTime _selectedDate;
  late Future<List<ScheduleItem>> _scheduleFuture;
  Future<Set<DateTime>>? _scheduledDatesFuture;
  var _isRedirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _weekStart = _mondayOf(_selectedDate);
    _scheduleFuture = _fetchSchedule();
    _scheduledDatesFuture = _fetchScheduledDates();
  }

  Future<List<ScheduleItem>> _fetchSchedule() {
    return _service.fetchScheduleForDate(
      _selectedDate,
      scope: widget.scope,
      studentId: widget.studentId,
    );
  }

  Future<Set<DateTime>> _fetchScheduledDates() async {
    final items = await _service.fetchWeeklySchedule(
      _weekStart,
      scope: widget.scope,
      studentId: widget.studentId,
    );
    return items.map((item) => _dateOnly(item.studyDate)).toSet();
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: offset * 7));
      _selectedDate = _selectedDate.add(Duration(days: offset * 7));
      _scheduleFuture = _fetchSchedule();
      _scheduledDatesFuture = _fetchScheduledDates();
    });
  }

  Future<void> _reload() async {
    final scheduleFuture = _fetchSchedule();
    final scheduledDatesFuture = _fetchScheduledDates();
    setState(() {
      _scheduleFuture = scheduleFuture;
      _scheduledDatesFuture = scheduledDatesFuture;
    });
    await scheduleFuture;
    await scheduledDatesFuture.catchError((_) => <DateTime>{});
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _scheduleFuture = _fetchSchedule();
    });
  }

  void _redirectToLoginIfNeeded(Object? error) {
    if (error is! SessionExpiredException || _isRedirectingToLogin) return;
    _isRedirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
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
            _buildHeader(context),
            _buildScopeBanner(),
            Expanded(
              child: FutureBuilder<List<ScheduleItem>>(
                future: _scheduleFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _navy),
                    );
                  }
                  if (snapshot.hasError) {
                    _redirectToLoginIfNeeded(snapshot.error);
                    return _LoadError(error: snapshot.error, onRetry: _reload);
                  }
                  return _buildSchedule(snapshot.data ?? const []);
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
    return Container(
      color: _navy,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 32,
                ),
                tooltip: 'Back',
              ),
              const Text(
                'Home',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Expanded(
                child: Text(
                  _screenTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 74),
            ],
          ),
        ),
      ),
    );
  }

  String get _screenTitle {
    return switch (widget.scope) {
      ScheduleScope.teacher => 'Lịch dạy',
      ScheduleScope.parent => 'Lịch · ${widget.studentName ?? 'Học sinh'}',
      ScheduleScope.student => 'Weekly timetable',
    };
  }

  Widget _buildScopeBanner() {
    final message = switch (widget.scope) {
      ScheduleScope.teacher => 'Lịch giảng dạy theo ngày',
      ScheduleScope.parent =>
        'Lịch học của ${widget.studentName ?? 'sinh viên đã chọn'}',
      ScheduleScope.student => 'Lịch học theo ngày',
    };
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Icon(
            widget.scope == ScheduleScope.teacher
                ? Icons.co_present_outlined
                : Icons.school_outlined,
            color: _navy,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(List<ScheduleItem> items) {
    return RefreshIndicator(
      onRefresh: _reload,
      color: _navy,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Current week: ${_formatDate(_weekStart)} – ${_formatDate(_weekStart.add(const Duration(days: 6)))}',
              style: const TextStyle(
                color: Color(0xFF697386),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 9),
          _buildMonthNavigator(),
          const SizedBox(height: 8),
          _buildDateStrip(),
          const Divider(height: 20, color: Color(0xFFE4E7ED)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Schedule for ${_formatDate(_selectedDate)}',
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (items.isEmpty)
            _EmptySchedule(
              onRetry: _reload,
              selectedDateLabel: _formatDate(_selectedDate),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Column(children: items.map(_ScheduleEntry.new).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeWeek(-1),
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            color: _navy,
            tooltip: 'Previous week',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
          Expanded(
            child: Text(
              _monthLabel(_weekStart),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeWeek(1),
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            color: _navy,
            tooltip: 'Next week',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return FutureBuilder<Set<DateTime>>(
      future: _scheduledDatesFuture ??= _fetchScheduledDates(),
      builder: (context, snapshot) {
        return _buildDateStripContent(snapshot.data ?? const <DateTime>{});
      },
    );
  }

  Widget _buildDateStripContent(Set<DateTime> scheduledDates) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: List.generate(7, (index) {
        final day = _weekStart.add(Duration(days: index));
        final selected = _sameDate(day, _selectedDate);
        final hasSchedule = scheduledDates.any(
          (scheduledDate) => _sameDate(scheduledDate, day),
        );
        return Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectDate(day),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    Text(
                      days[index],
                      style: const TextStyle(
                        color: Color(0xFF778091),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 29,
                      height: 29,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? _navy
                            : hasSchedule
                            ? const Color(0xFFFFF1E3)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: hasSchedule
                            ? Border.all(
                                color: selected
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFFFFB25F),
                                width: selected ? 2 : 1,
                              )
                            : null,
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: selected ? Colors.white : _text,
                          fontSize: 14,
                          fontWeight: selected || hasSchedule
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNavigation() {
    return MainBottomNavigation(
      onHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
      onEvents: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const EventsFeedScreen())),
      onProfile: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
    );
  }

  static DateTime _mondayOf(DateTime date) {
    final normalized = _dateOnly(date);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  static String _monthLabel(DateTime date) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }
}

class _ScheduleEntry extends StatelessWidget {
  const _ScheduleEntry(this.entry);

  final ScheduleItem entry;

  @override
  Widget build(BuildContext context) {
    final accent = entry.id.isEven
        ? const Color(0xFF2CD52C)
        : const Color(0xFFA43D0F);
    final status = _attendanceStatus(entry.studyDate);
    final note = entry.note;
    final lecturer = entry.lecturerName;
    final isTeachingSchedule = entry.studentCount != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 154,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 48,
            child: Column(
              children: [
                _SlotBadge(
                  color: accent,
                  label: 'Slot ${_slotNumber(entry.startTime)}',
                ),
                const SizedBox(height: 9),
                Text(
                  entry.startTime,
                  style: const TextStyle(
                    color: Color(0xFF8A94A5),
                    fontSize: 12,
                  ),
                ),
                Container(width: 1, height: 17, color: const Color(0xFFD8DEE8)),
                Text(
                  entry.endTime,
                  style: const TextStyle(
                    color: Color(0xFF8A94A5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F6),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Room',
                        style: TextStyle(
                          color: Color(0xFFA0A7B4),
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        entry.room ?? 'TBA',
                        style: const TextStyle(
                          color: Color(0xFF243651),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.subjectCode.isEmpty
                      ? entry.subjectName
                      : entry.subjectCode,
                  style: const TextStyle(
                    color: Color(0xFF566074),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (entry.subjectName.isNotEmpty)
                  Text(
                    entry.subjectName,
                    style: const TextStyle(
                      color: Color(0xFF566074),
                      fontSize: 12,
                    ),
                  ),
                if (note != null)
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6A7484),
                      fontSize: 12,
                    ),
                  ),
                if (!isTeachingSchedule && lecturer != null)
                  Text(
                    'Lecturer: $lecturer',
                    style: const TextStyle(
                      color: Color(0xFF6A7484),
                      fontSize: 12,
                    ),
                  ),
                if (isTeachingSchedule && entry.classNames.isNotEmpty)
                  Text(
                    'Lớp: ${entry.classNames.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6A7484),
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _StatusBadge(label: status.$1, color: status.$2),
                    if (entry.studentCount != null)
                      _StatusBadge(
                        label: '${entry.studentCount} sinh viên',
                        color: const Color(0xFFFF9500),
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

  (String, Color) _attendanceStatus(DateTime date) {
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    if (entryDate.isBefore(current)) {
      return ('ĐÃ QUA', const Color(0xFF39CD39));
    }
    if (entryDate == current) {
      return ('HÔM NAY', const Color(0xFF377BDF));
    }
    return ('SẮP TỚI', const Color(0xFF8E9295));
  }

  int _slotNumber(String time) {
    final hour = int.tryParse(time.split(':').first) ?? 7;
    if (hour < 9) return 1;
    if (hour < 12) return 2;
    if (hour < 15) return 3;
    return 4;
  }
}

class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  const _EmptySchedule({
    required this.onRetry,
    required this.selectedDateLabel,
  });

  final Future<void> Function() onRetry;
  final String selectedDateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 58, 28, 30),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 56,
            color: Color(0xFF9BA8B9),
          ),
          const SizedBox(height: 14),
          Text(
            'No classes on $selectedDateLabel',
            style: const TextStyle(
              color: Color(0xFF243651),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Tap another date or pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF697386)),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    final message = failure is SessionExpiredException
        ? failure.message
        : _cleanError(failure);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color: Color(0xFFA34A38),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF4B5565), height: 1.4),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanError(Object? error) {
    final message = error?.toString().trim() ?? '';
    if (message.isEmpty) {
      return 'Không thể tải lịch. Vui lòng kiểm tra kết nối máy chủ.';
    }
    return message
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
  }
}
