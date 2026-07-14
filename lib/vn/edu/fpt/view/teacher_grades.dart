import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/teacher_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';

class TeacherGradesScreen extends StatefulWidget {
  const TeacherGradesScreen({super.key});

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen> {
  static const _navy = Color(0xFF183A66);
  static const _canvas = Color(0xFFF4F6FA);

  final TeacherService _service = const TeacherService();
  final TextEditingController _searchController = TextEditingController();

  List<SchoolSemester> _semesters = const [];
  List<SchoolSubject> _subjects = const [];
  List<LinkedStudent> _students = const [];
  List<TeacherGrade> _grades = const [];
  int? _semesterId;
  int? _subjectId;
  String _search = '';
  Object? _error;
  bool _loading = true;
  bool _redirectingToLogin = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  @override
  void dispose() {
    _loadGeneration++;
    _searchController.dispose();
    super.dispose();
  }

  List<LinkedStudent> get _filteredStudents {
    final keyword = _search.trim().toLowerCase();
    if (keyword.isEmpty) return _students;
    return _students
        .where((student) {
          return <String?>[
            student.userName,
            student.fullName,
            student.email,
            student.className,
          ].any((value) => value?.toLowerCase().contains(keyword) ?? false);
        })
        .toList(growable: false);
  }

  Future<void> _loadSemesters() async {
    final generation = ++_loadGeneration;
    _setLoading(clearSelections: true);
    try {
      final semesters = await _service.fetchSemesters();
      if (!mounted || generation != _loadGeneration) return;
      if (semesters.isEmpty) {
        setState(() {
          _semesters = const [];
          _loading = false;
        });
        return;
      }

      final selected = _currentSemester(semesters);
      setState(() {
        _semesters = semesters;
        _semesterId = selected.id;
      });
      await _loadSemester(selected.id);
    } catch (error) {
      _handleLoadError(error, generation);
    }
  }

  Future<void> _loadSemester(int semesterId) async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _semesterId = semesterId;
        _subjectId = null;
        _subjects = const [];
        _students = const [];
        _grades = const [];
        _error = null;
        _loading = true;
      });
    }

    try {
      final subjects = await _service.fetchSubjects(semesterId: semesterId);
      if (!mounted || generation != _loadGeneration) return;
      if (subjects.isEmpty) {
        setState(() {
          _subjects = const [];
          _loading = false;
        });
        return;
      }

      final subjectId = subjects.first.id;
      final results = await Future.wait<Object>([
        _service.fetchStudents(subjectId: subjectId, semesterId: semesterId),
        _service.fetchGrades(subjectId: subjectId, semesterId: semesterId),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _subjects = subjects;
        _subjectId = subjectId;
        _students = results[0] as List<LinkedStudent>;
        _grades = results[1] as List<TeacherGrade>;
        _loading = false;
      });
    } catch (error) {
      _handleLoadError(error, generation);
    }
  }

  Future<void> _loadSubject(int subjectId) async {
    final semesterId = _semesterId;
    if (semesterId == null) return;
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _subjectId = subjectId;
        _students = const [];
        _grades = const [];
        _error = null;
        _loading = true;
      });
    }

    try {
      final results = await Future.wait<Object>([
        _service.fetchStudents(subjectId: subjectId, semesterId: semesterId),
        _service.fetchGrades(subjectId: subjectId, semesterId: semesterId),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _students = results[0] as List<LinkedStudent>;
        _grades = results[1] as List<TeacherGrade>;
        _loading = false;
      });
    } catch (error) {
      _handleLoadError(error, generation);
    }
  }

  void _setLoading({bool clearSelections = false}) {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _students = const [];
      _grades = const [];
      if (clearSelections) {
        _semesters = const [];
        _subjects = const [];
        _semesterId = null;
        _subjectId = null;
      }
    });
  }

  void _handleLoadError(Object error, int generation) {
    if (!mounted || generation != _loadGeneration) return;
    if (error is SessionExpiredException) {
      _redirectToLogin();
    }
    setState(() {
      _error = error;
      _loading = false;
    });
  }

  SchoolSemester _currentSemester(List<SchoolSemester> semesters) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final semester in semesters) {
      if (!today.isBefore(semester.startDate) &&
          !today.isAfter(semester.endDate)) {
        return semester;
      }
    }
    return semesters.first;
  }

  Future<void> _reload() async {
    final subjectId = _subjectId;
    if (subjectId != null) {
      await _loadSubject(subjectId);
      return;
    }
    final semesterId = _semesterId;
    if (semesterId != null) {
      await _loadSemester(semesterId);
      return;
    }
    await _loadSemesters();
  }

  Future<void> _openEditor(LinkedStudent student, TeacherGrade? grade) async {
    final semesterId = _semesterId;
    final subjectId = _subjectId;
    if (semesterId == null || subjectId == null) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _GradeEditorSheet(
        student: student,
        grade: grade,
        onSave: (items) async {
          try {
            if (grade == null) {
              await _service.createGrade(
                userId: student.id,
                subjectId: subjectId,
                semesterId: semesterId,
                items: items,
              );
            } else {
              await _service.updateGrade(
                gradeId: grade.id,
                userId: student.id,
                subjectId: subjectId,
                semesterId: semesterId,
                items: items,
              );
            }
          } on SessionExpiredException {
            _redirectToLogin();
            rethrow;
          }
        },
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            grade == null
                ? 'Đã nhập điểm cho ${student.fullName}'
                : 'Đã cập nhật điểm của ${student.fullName}',
          ),
        ),
      );
      await _loadSubject(subjectId);
    }
  }

  void _redirectToLogin() {
    if (_redirectingToLogin) return;
    _redirectingToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gradesByStudent = <int, TeacherGrade>{
      for (final grade in _grades) grade.userId: grade,
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          title: const Text(
            'Quản lý điểm',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildBody(gradesByStudent)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('semester-$_semesterId'),
                  initialValue: _semesterId,
                  isExpanded: true,
                  decoration: _selectorDecoration(
                    'Học kỳ',
                    Icons.calendar_today_outlined,
                  ),
                  items: _semesters
                      .map(
                        (semester) => DropdownMenuItem<int>(
                          value: semester.id,
                          child: Text(
                            semester.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null && value != _semesterId) {
                            _loadSemester(value);
                          }
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('subject-$_semesterId-$_subjectId'),
                  initialValue: _subjectId,
                  isExpanded: true,
                  decoration: _selectorDecoration(
                    'Môn được phân công',
                    Icons.menu_book_outlined,
                  ),
                  items: _subjects
                      .map(
                        (subject) => DropdownMenuItem<int>(
                          value: subject.id,
                          child: Text(
                            subject.subjectCode.isEmpty
                                ? subject.subjectName
                                : subject.subjectCode,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null && value != _subjectId) {
                            _loadSubject(value);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, mã sinh viên hoặc lớp',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xóa tìm kiếm',
                    ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _selectorDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildBody(Map<int, TeacherGrade> gradesByStudent) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }
    if (_error != null) {
      return _TeacherStateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Không thể tải dữ liệu điểm',
        message: _errorText(_error),
        actionLabel: 'Thử lại',
        onAction: _reload,
      );
    }
    if (_semesters.isEmpty) {
      return _TeacherStateMessage(
        icon: Icons.calendar_month_outlined,
        title: 'Chưa có học kỳ',
        message: 'Không có học kỳ nào để quản lý điểm.',
        actionLabel: 'Tải lại',
        onAction: _loadSemesters,
      );
    }
    if (_subjects.isEmpty) {
      return _TeacherStateMessage(
        icon: Icons.menu_book_outlined,
        title: 'Chưa được phân công môn',
        message: 'Bạn chưa có môn học nào được phân công trong học kỳ đã chọn.',
        actionLabel: 'Tải lại',
        onAction: _reload,
      );
    }
    if (_students.isEmpty) {
      return _TeacherStateMessage(
        icon: Icons.groups_outlined,
        title: 'Chưa có sinh viên',
        message: 'Môn học này chưa có sinh viên được ghi danh.',
        actionLabel: 'Tải lại',
        onAction: _reload,
      );
    }

    final students = _filteredStudents;
    if (students.isEmpty) {
      return const _TeacherStateMessage(
        icon: Icons.person_search_outlined,
        title: 'Không tìm thấy sinh viên',
        message: 'Hãy thử một từ khóa khác.',
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: _navy,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        itemCount: students.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(3, 0, 3, 10),
              child: Row(
                children: [
                  Text(
                    '${students.length} sinh viên',
                    style: const TextStyle(
                      color: Color(0xFF34445C),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.lock_outline,
                    size: 15,
                    color: Color(0xFF778397),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Môn được phân công',
                    style: TextStyle(color: Color(0xFF778397), fontSize: 11),
                  ),
                ],
              ),
            );
          }
          final student = students[index - 1];
          final grade = gradesByStudent[student.id];
          return _StudentGradeCard(
            student: student,
            grade: grade,
            onEdit: () => _openEditor(student, grade),
          );
        },
      ),
    );
  }

  String _errorText(Object? error) {
    if (error is SessionExpiredException) return error.message;
    final message = error.toString().replaceFirst(
      RegExp(r'^(Exception|ApiException):\s*'),
      '',
    );
    return message.isEmpty ? 'Đã xảy ra lỗi không xác định.' : message;
  }
}

class _StudentGradeCard extends StatelessWidget {
  const _StudentGradeCard({
    required this.student,
    required this.grade,
    required this.onEdit,
  });

  final LinkedStudent student;
  final TeacherGrade? grade;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final currentGrade = grade;
    final name = student.fullName.trim().isEmpty
        ? student.userName
        : student.fullName;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 11),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFE2E7EE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8F1FC),
                  foregroundColor: _TeacherGradesScreenState._navy,
                  child: Text(
                    name.isEmpty ? 'S' : name.characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF25364E),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          student.userName,
                          if (student.className?.isNotEmpty ?? false)
                            student.className!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF778397),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentGrade == null)
                  const _GradeStatusChip(label: 'Chưa nhập')
                else
                  _GradeStatusChip(
                    label: currentGrade.letterGrade?.isNotEmpty ?? false
                        ? currentGrade.letterGrade!
                        : currentGrade.totalScore?.toStringAsFixed(1) ?? '—',
                    hasGrade: true,
                  ),
              ],
            ),
            const SizedBox(height: 13),
            if (currentGrade == null)
              const Text(
                'Sinh viên chưa có điểm cho môn học này.',
                style: TextStyle(color: Color(0xFF7A8596), fontSize: 12.5),
              )
            else ...[
              Row(
                children: [
                  _GradeMetric(
                    label: 'Điểm tổng',
                    value: currentGrade.totalScore?.toStringAsFixed(2) ?? '—',
                  ),
                  const SizedBox(width: 9),
                  _GradeMetric(
                    label: 'Đầu điểm',
                    value: '${currentGrade.items.length}',
                  ),
                ],
              ),
              if (currentGrade.items.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  currentGrade.items
                      .map(
                        (item) =>
                            '${item.name}: ${_formatNumber(item.score)} (${_formatNumber(item.weight)}%)',
                      )
                      .join('  ·  '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF677489),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onEdit,
                icon: Icon(
                  currentGrade == null ? Icons.add_chart : Icons.edit_note,
                ),
                label: Text(
                  currentGrade == null ? 'Nhập điểm' : 'Chỉnh sửa điểm',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _GradeStatusChip extends StatelessWidget {
  const _GradeStatusChip({required this.label, this.hasGrade = false});

  final String label;
  final bool hasGrade;

  @override
  Widget build(BuildContext context) {
    final color = hasGrade ? const Color(0xFF168A65) : const Color(0xFF7B8493);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GradeMetric extends StatelessWidget {
  const _GradeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7B8697), fontSize: 10.5),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2A3B53),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeEditorSheet extends StatefulWidget {
  const _GradeEditorSheet({
    required this.student,
    required this.grade,
    required this.onSave,
  });

  final LinkedStudent student;
  final TeacherGrade? grade;
  final Future<void> Function(List<TeacherGradeItem> items) onSave;

  @override
  State<_GradeEditorSheet> createState() => _GradeEditorSheetState();
}

class _GradeEditorSheetState extends State<_GradeEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final List<_GradeItemDraft> _items;
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.grade?.items ?? const <TeacherGradeItem>[];
    _items = existing.isEmpty
        ? [
            _GradeItemDraft(name: 'PT1', weight: '50'),
            _GradeItemDraft(name: 'PT2', weight: '50'),
          ]
        : existing
              .map(
                (item) => _GradeItemDraft(
                  name: item.name,
                  weight: _displayNumber(item.weight),
                  score: _displayNumber(item.score),
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  double get _weightTotal => _items.fold<double>(
    0,
    (total, item) => total + (_parseDecimal(item.weight.text) ?? 0),
  );

  void _addItem() {
    if (_items.length >= 20) return;
    setState(() {
      _items.add(_GradeItemDraft());
      _formError = null;
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    final removed = _items.removeAt(index);
    removed.dispose();
    setState(() => _formError = null);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final validFields = _formKey.currentState?.validate() ?? false;
    final total = _weightTotal;
    if (!validFields || (total - 100).abs() > .0001) {
      setState(() {
        _formError = (total - 100).abs() > .0001
            ? 'Tổng trọng số phải đúng 100% (hiện tại ${_displayNumber(total)}%).'
            : 'Vui lòng kiểm tra lại các đầu điểm.';
      });
      return;
    }

    final items = _items
        .map(
          (item) => TeacherGradeItem(
            name: item.name.text.trim(),
            weight: _parseDecimal(item.weight.text)!,
            score: _parseDecimal(item.score.text)!,
          ),
        )
        .toList(growable: false);

    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      await widget.onSave(items);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = _cleanError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final studentName = widget.student.fullName.trim().isEmpty
        ? widget.student.userName
        : widget.student.fullName;

    return FractionallySizedBox(
      heightFactor: .94,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 10, 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.grade == null ? 'Nhập điểm' : 'Chỉnh sửa điểm',
                          style: const TextStyle(
                            color: Color(0xFF25364D),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$studentName · ${widget.student.userName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF748095),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _WeightSummary(
                      total: _weightTotal,
                      itemCount: _items.length,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 10),
                      _InlineError(message: _formError!),
                    ],
                    const SizedBox(height: 14),
                    for (var index = 0; index < _items.length; index++) ...[
                      _GradeItemEditor(
                        key: ObjectKey(_items[index]),
                        index: index,
                        draft: _items[index],
                        canRemove: _items.length > 1,
                        onRemove: () => _removeItem(index),
                        onChanged: () => setState(() => _formError = null),
                      ),
                      const SizedBox(height: 11),
                    ],
                    OutlinedButton.icon(
                      onPressed: _items.length >= 20 || _saving
                          ? null
                          : _addItem,
                      icon: const Icon(Icons.add),
                      label: Text(
                        _items.length >= 20
                            ? 'Tối đa 20 đầu điểm'
                            : 'Thêm đầu điểm',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE4E8EE))),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Đang lưu...' : 'Lưu điểm'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double? _parseDecimal(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value?.isFinite == true ? value : null;
  }

  static String _displayNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _cleanError(Object error) {
    return error.toString().replaceFirst(
      RegExp(r'^(Exception|ApiException):\s*'),
      '',
    );
  }
}

class _GradeItemDraft {
  _GradeItemDraft({String name = '', String weight = '', String score = ''})
    : name = TextEditingController(text: name),
      weight = TextEditingController(text: weight),
      score = TextEditingController(text: score);

  final TextEditingController name;
  final TextEditingController weight;
  final TextEditingController score;

  void dispose() {
    name.dispose();
    weight.dispose();
    score.dispose();
  }
}

class _GradeItemEditor extends StatelessWidget {
  const _GradeItemEditor({
    super.key,
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _GradeItemDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E6EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Đầu điểm ${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF425169),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: canRemove ? onRemove : null,
                tooltip: 'Xóa đầu điểm',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: TextFormField(
              controller: draft.name,
              onChanged: (_) => onChanged(),
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Tên đầu điểm',
                hintText: 'Ví dụ: PT1, Final',
                counterText: '',
                isDense: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Không được để trống';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.weight,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Trọng số (%)',
                      isDense: true,
                    ),
                    validator: (value) {
                      final parsed = _GradeEditorSheetState._parseDecimal(
                        value ?? '',
                      );
                      if (parsed == null || parsed <= 0 || parsed > 100) {
                        return 'Phải > 0 và ≤ 100';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: draft.score,
                    onChanged: (_) => onChanged(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Điểm (0–10)',
                      isDense: true,
                    ),
                    validator: (value) {
                      final parsed = _GradeEditorSheetState._parseDecimal(
                        value ?? '',
                      );
                      if (parsed == null || parsed < 0 || parsed > 10) {
                        return 'Từ 0 đến 10';
                      }
                      return null;
                    },
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

class _WeightSummary extends StatelessWidget {
  const _WeightSummary({required this.total, required this.itemCount});

  final double total;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final valid = (total - 100).abs() <= .0001;
    final color = valid ? const Color(0xFF178A65) : const Color(0xFFD06A24);
    final progress = math.min(math.max(total / 100, 0), 1).toDouble();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.percent, size: 18, color: color),
              const SizedBox(width: 7),
              Text(
                '$itemCount đầu điểm',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${_GradeEditorSheetState._displayNumber(total)} / 100%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.white,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 19, color: Color(0xFFB63D43)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9E353A),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherStateMessage extends StatelessWidget {
  const _TeacherStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFF95A1B3)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF293A52),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6D798B), height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 15),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
