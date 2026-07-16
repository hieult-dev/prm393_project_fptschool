import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/student_application_service.dart';

class TeacherApplicationsScreen extends StatefulWidget {
  const TeacherApplicationsScreen({super.key});

  @override
  State<TeacherApplicationsScreen> createState() =>
      _TeacherApplicationsScreenState();
}

class _TeacherApplicationsScreenState extends State<TeacherApplicationsScreen> {
  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF8A3D);
  static const _background = Color(0xFFF5F6FB);
  static const _text = Color(0xFF243650);
  static const _muted = Color(0xFF68758A);

  final _service = const StudentApplicationService();

  var _loading = true;
  var _statusFilter = 'PENDING';
  int? _reviewingId;
  String? _error;
  List<StudentApplication> _applications = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final applications = await _service.fetchTeacherApplications();
      if (!mounted) return;
      setState(() {
        _applications = applications;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<StudentApplication> get _visibleApplications {
    if (_statusFilter == 'ALL') return _applications;
    return _applications
        .where((item) => item.status.toUpperCase() == _statusFilter)
        .toList(growable: false);
  }

  Future<void> _openReviewSheet(
    StudentApplication application,
    String status,
  ) async {
    final responseNote = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ReviewApplicationSheet(application: application, status: status),
    );
    if (responseNote == null) return;
    await _reviewApplication(application, status, responseNote);
  }

  Future<void> _reviewApplication(
    StudentApplication application,
    String status,
    String responseNote,
  ) async {
    if (_reviewingId != null) return;
    setState(() {
      _reviewingId = application.id;
    });

    try {
      final reviewed = await _service.reviewTeacherApplication(
        applicationId: application.id,
        status: status,
        responseNote: responseNote,
      );
      if (!mounted) return;
      setState(() {
        _applications = _applications
            .map((item) => item.id == reviewed.id ? reviewed : item)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'APPROVED' ? 'Đã duyệt đơn' : 'Đã từ chối đơn',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) {
        setState(() {
          _reviewingId = null;
        });
      }
    }
  }

  String _message(Object error) {
    if (error is ApiException) return error.message;
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|FormatException):\s*'), '')
        .trim();
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
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          title: const Text(
            'Đơn phụ huynh',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: _navy,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
              children: [
                _SummaryCard(applications: _applications),
                const SizedBox(height: 14),
                _buildFilters(),
                const SizedBox(height: 16),
                if (_loading)
                  const _LoadingState()
                else if (_error != null)
                  _ErrorState(message: _error!, onRetry: _load)
                else if (_visibleApplications.isEmpty)
                  _EmptyState(filter: _statusFilter)
                else
                  ..._visibleApplications.map(
                    (application) => _ApplicationReviewCard(
                      application: application,
                      reviewing: _reviewingId == application.id,
                      onApprove: () =>
                          _openReviewSheet(application, 'APPROVED'),
                      onReject: () => _openReviewSheet(application, 'REJECTED'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatusFilterChip(
            label: 'Chờ phản hồi',
            selected: _statusFilter == 'PENDING',
            onTap: () => _changeStatus('PENDING'),
          ),
          _StatusFilterChip(
            label: 'Tất cả',
            selected: _statusFilter == 'ALL',
            onTap: () => _changeStatus('ALL'),
          ),
          _StatusFilterChip(
            label: 'Đã duyệt',
            selected: _statusFilter == 'APPROVED',
            onTap: () => _changeStatus('APPROVED'),
          ),
          _StatusFilterChip(
            label: 'Từ chối',
            selected: _statusFilter == 'REJECTED',
            onTap: () => _changeStatus('REJECTED'),
          ),
        ],
      ),
    );
  }

  void _changeStatus(String status) {
    if (_statusFilter == status) return;
    setState(() {
      _statusFilter = status;
    });
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.applications});

  final List<StudentApplication> applications;

  @override
  Widget build(BuildContext context) {
    final pending = applications
        .where((item) => item.status.toUpperCase() == 'PENDING')
        .length;
    final approved = applications
        .where((item) => item.status.toUpperCase() == 'APPROVED')
        .length;
    final rejected = applications
        .where((item) => item.status.toUpperCase() == 'REJECTED')
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F183A66),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFE4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: _TeacherApplicationsScreenState._orange,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn từ phụ huynh',
                      style: TextStyle(
                        color: _TeacherApplicationsScreenState._text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Xem và phản hồi đơn của lớp chủ nhiệm.',
                      style: TextStyle(
                        color: _TeacherApplicationsScreenState._muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'Chờ',
                  value: pending,
                  color: const Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  label: 'Duyệt',
                  value: approved,
                  color: const Color(0xFF18A56F),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  label: 'Từ chối',
                  value: rejected,
                  color: const Color(0xFFE55353),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicationReviewCard extends StatelessWidget {
  const _ApplicationReviewCard({
    required this.application,
    required this.reviewing,
    required this.onApprove,
    required this.onReject,
  });

  final StudentApplication application;
  final bool reviewing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(application.status);
    final pending = application.status.toUpperCase() == 'PENDING';
    final studentName = _fallback(
      application.studentName,
      application.studentCode ?? 'Sinh viên #${application.userId}',
    );
    final parentName = _fallback(
      application.parentName,
      application.parentUserName ?? 'Phụ huynh',
    );
    final typeName = _fallback(
      application.applicationTypeName,
      'Loại đơn #${application.applicationTypeId}',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  application.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _TeacherApplicationsScreenState._text,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$typeName · ${_formatDate(application.createdAt)}',
            style: const TextStyle(
              color: Color(0xFF7B8497),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _InfoLine(
            icon: Icons.school_outlined,
            text: [
              studentName,
              if ((application.className ?? '').trim().isNotEmpty)
                application.className!.trim(),
            ].join(' · '),
          ),
          const SizedBox(height: 7),
          _InfoLine(icon: Icons.family_restroom_rounded, text: parentName),
          const SizedBox(height: 12),
          Text(
            application.content,
            style: const TextStyle(
              color: Color(0xFF48566D),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if ((application.responseNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phản hồi của giáo viên',
                    style: TextStyle(
                      color: _TeacherApplicationsScreenState._navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    application.responseNote!.trim(),
                    style: const TextStyle(
                      color: Color(0xFF48566D),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (pending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: reviewing ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 19),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: const Color(0xFFE55353),
                      side: const BorderSide(color: Color(0xFFF3B6B6)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: reviewing ? null : onApprove,
                    icon: reviewing
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 19),
                    label: const Text('Duyệt'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: const Color(0xFF18A56F),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  ({String label, Color color}) _statusInfo(String status) {
    return switch (status.toUpperCase()) {
      'APPROVED' => (label: 'Đã duyệt', color: const Color(0xFF18A56F)),
      'REJECTED' => (label: 'Từ chối', color: const Color(0xFFE55353)),
      _ => (label: 'Chờ phản hồi', color: const Color(0xFFFF9800)),
    };
  }

  String _fallback(String? value, String fallback) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa có ngày';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}

class _ReviewApplicationSheet extends StatefulWidget {
  const _ReviewApplicationSheet({
    required this.application,
    required this.status,
  });

  final StudentApplication application;
  final String status;

  @override
  State<_ReviewApplicationSheet> createState() =>
      _ReviewApplicationSheetState();
}

class _ReviewApplicationSheetState extends State<_ReviewApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_responseController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final approve = widget.status == 'APPROVED';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E5EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                approve ? 'Duyệt đơn' : 'Từ chối đơn',
                style: const TextStyle(
                  color: _TeacherApplicationsScreenState._text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.application.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _TeacherApplicationsScreenState._muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _responseController,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Nội dung phản hồi',
                  hintText: 'Nhập phản hồi gửi cho phụ huynh',
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Vui lòng nhập nội dung phản hồi'
                    : null,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: Icon(
                        approve ? Icons.check_rounded : Icons.close_rounded,
                      ),
                      label: Text(approve ? 'Duyệt' : 'Từ chối'),
                      style: FilledButton.styleFrom(
                        backgroundColor: approve
                            ? const Color(0xFF18A56F)
                            : const Color(0xFFE55353),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFFFEFE4),
        labelStyle: TextStyle(
          color: selected
              ? _TeacherApplicationsScreenState._orange
              : const Color(0xFF667085),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selected
              ? _TeacherApplicationsScreenState._orange
              : const Color(0xFFE1E5EE),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _TeacherApplicationsScreenState._navy),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF56647A),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 44),
      child: Center(
        child: CircularProgressIndicator(
          color: _TeacherApplicationsScreenState._navy,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE55353), size: 44),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF56647A), height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final String filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      'PENDING' => 'Chưa có đơn nào cần phản hồi.',
      'APPROVED' => 'Chưa có đơn nào đã được duyệt.',
      'REJECTED' => 'Chưa có đơn nào bị từ chối.',
      _ => 'Chưa có đơn phụ huynh nào.',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF9AA8BD),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Không có đơn',
            style: TextStyle(
              color: _TeacherApplicationsScreenState._text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7B8497)),
          ),
        ],
      ),
    );
  }
}
