import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/school_models.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/student_application_service.dart';

class StudentApplicationsScreen extends StatefulWidget {
  const StudentApplicationsScreen({super.key});

  @override
  State<StudentApplicationsScreen> createState() =>
      _StudentApplicationsScreenState();
}

class _StudentApplicationsScreenState extends State<StudentApplicationsScreen> {
  final _service = const StudentApplicationService();

  var _loading = true;
  var _submitting = false;
  var _statusFilter = 'ALL';
  String? _error;
  List<ApplicationType> _types = const [];
  List<StudentApplication> _applications = const [];

  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF7628);
  static const _background = Color(0xFFF5F6FB);
  static const _text = Color(0xFF1E2233);
  static const _muted = Color(0xFF7B8497);

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
      final values = await Future.wait<Object>([
        _service.fetchApplicationTypes(),
        _service.fetchApplications(
          status: _statusFilter == 'ALL' ? null : _statusFilter,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _types = values[0] as List<ApplicationType>;
        _applications = values[1] as List<StudentApplication>;
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

  Future<void> _openCreateSheet() async {
    if (_types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có loại đơn để tạo đơn mới')),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CreateApplicationSheet(types: _types, onSubmit: _createApplication),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _createApplication({
    required int applicationTypeId,
    required String title,
    required String content,
  }) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
    });

    try {
      await _service.createApplication(
        applicationTypeId: applicationTypeId,
        title: title,
        content: content,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi đơn. Vui lòng chờ admin phản hồi.'),
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
          _submitting = false;
        });
      }
    }
  }

  String _typeName(int typeId) {
    final matches = _types.where((type) => type.id == typeId);
    return matches.isEmpty ? 'Loại đơn #$typeId' : matches.first.name;
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
          title: const Text('Đơn từ'),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          onPressed: _loading ? null : _openCreateSheet,
          icon: const Icon(Icons.edit_document),
          label: const Text('Viết đơn'),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              children: [
                _buildSummary(),
                const SizedBox(height: 14),
                _buildFilters(),
                const SizedBox(height: 16),
                if (_loading)
                  const _LoadingCard()
                else if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _load)
                else if (_applications.isEmpty)
                  const _EmptyCard()
                else
                  ..._applications.map(
                    (application) => _ApplicationCard(
                      application: application,
                      typeName:
                          application.applicationTypeName ??
                          _typeName(application.applicationTypeId),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final pending = _applications
        .where((item) => item.status.toUpperCase() == 'PENDING')
        .length;
    final approved = _applications
        .where((item) => item.status.toUpperCase() == 'APPROVED')
        .length;
    final rejected = _applications
        .where((item) => item.status.toUpperCase() == 'REJECTED')
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F183A66),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theo dõi đơn từ',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gửi đơn cho admin và xem trạng thái phản hồi tại đây.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'Chờ duyệt', value: pending),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(label: 'Đã duyệt', value: approved),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatPill(label: 'Từ chối', value: rejected),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Tất cả',
            selected: _statusFilter == 'ALL',
            onTap: () => _changeStatus('ALL'),
          ),
          _FilterChip(
            label: 'Chờ duyệt',
            selected: _statusFilter == 'PENDING',
            onTap: () => _changeStatus('PENDING'),
          ),
          _FilterChip(
            label: 'Đã duyệt',
            selected: _statusFilter == 'APPROVED',
            onTap: () => _changeStatus('APPROVED'),
          ),
          _FilterChip(
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
    _load();
  }
}

class _CreateApplicationSheet extends StatefulWidget {
  const _CreateApplicationSheet({required this.types, required this.onSubmit});

  final List<ApplicationType> types;
  final Future<void> Function({
    required int applicationTypeId,
    required String title,
    required String content,
  })
  onSubmit;

  @override
  State<_CreateApplicationSheet> createState() =>
      _CreateApplicationSheetState();
}

class _CreateApplicationSheetState extends State<_CreateApplicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late int _typeId = widget.types.first.id;
  var _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
    });
    try {
      await widget.onSubmit(
        applicationTypeId: _typeId,
        title: _titleController.text,
        content: _contentController.text,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Viết đơn mới',
                style: TextStyle(
                  color: Color(0xFF1E2233),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _typeId,
                decoration: const InputDecoration(labelText: 'Loại đơn'),
                items: widget.types
                    .map(
                      (type) => DropdownMenuItem<int>(
                        value: type.id,
                        child: Text(type.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _typeId = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                enabled: !_submitting,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Nội dung đơn'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Vui lòng nhập nội dung đơn'
                    : null,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Đang gửi...' : 'Gửi đơn'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.typeName});

  final StudentApplication application;
  final String typeName;

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(application.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EDF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.title,
                  style: const TextStyle(
                    color: Color(0xFF1E2233),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$typeName · ${_formatDate(application.createdAt)}',
            style: const TextStyle(color: Color(0xFF7B8497), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            application.content,
            style: const TextStyle(
              color: Color(0xFF4D5870),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          if ((application.responseNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phản hồi admin',
                    style: TextStyle(
                      color: Color(0xFF183A66),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    application.responseNote!,
                    style: const TextStyle(
                      color: Color(0xFF4D5870),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
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
      _ => (label: 'Chờ duyệt', color: const Color(0xFFFF9800)),
    };
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa có ngày';
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        selectedColor: const Color(0xFFFFEFE6),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFFFF7628) : const Color(0xFF687386),
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(
          color: selected ? const Color(0xFFFF7628) : const Color(0xFFE1E5EE),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: Color(0xFF183A66),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7B8497), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 42),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.article_outlined, color: Color(0xFF9AA8BD), size: 48),
          SizedBox(height: 12),
          Text(
            'Chưa có đơn nào',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Bấm “Viết đơn” để gửi đơn mới cho admin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF7B8497)),
          ),
        ],
      ),
    );
  }
}
