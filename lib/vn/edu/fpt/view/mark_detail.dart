import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/mark_report_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';

class MarkDetailScreen extends StatefulWidget {
  const MarkDetailScreen({super.key, required this.gradeId});

  final int gradeId;

  @override
  State<MarkDetailScreen> createState() => _MarkDetailScreenState();
}

class _MarkDetailScreenState extends State<MarkDetailScreen> {
  static const _background = Color(0xFFF4F4F5);
  static const _topColor = Color(0xFF183455);
  static const _bottomColor = Color(0xFF183455);
  static const _headerTable = Color(0xFF112C4F);
  static const _orange = Color(0xFFFF9800);
  static const _green = Color(0xFF16C79A);
  static const _red = Color(0xFFFF3D45);
  static const _mutedText = Color(0xFF747B8F);
  static const _titleText = Color(0xFF1C3154);
  static const _line = Color(0xFFE7EAF0);

  late final Future<MarkDetail> _detailFuture;
  bool _redirectingToLogin = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = MarkReportService().fetchMarkDetail(
      gradeId: widget.gradeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _topColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _bottomColor,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Container(
                color: _topColor,
                child: SafeArea(bottom: false, child: _buildHeader(context)),
              ),
            ),
            Expanded(
              child: FutureBuilder<MarkDetail>(
                future: _detailFuture,
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
                    return _StateMessage(
                      icon: Icons.error_outline,
                      title: snapshot.error is SessionExpiredException
                          ? 'Session expired'
                          : 'Cannot load mark details',
                      message: _cleanError(snapshot.error),
                    );
                  }

                  final detail = snapshot.data;
                  if (detail == null) {
                    return const _StateMessage(
                      icon: Icons.table_chart_outlined,
                      title: 'No mark details',
                      message: 'There are no grade details to display.',
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _SubjectSummary(detail: detail),
                      const SizedBox(height: 14),
                      detail.items.isEmpty
                          ? const _StateMessage(
                              icon: Icons.table_chart_outlined,
                              title: 'No grade items',
                              message: 'This subject has no grade item data.',
                            )
                          : _GradeTable(items: detail.items),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
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

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.only(left: 2, right: 10),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.chevron_left, size: 32),
              label: const Text(
                'Mark Report',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Center(
            child: Text(
              'Mark Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: _bottomColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(
              Icons.cloud_queue_rounded,
              color: Color(0xFFD6DEE9),
              size: 22,
            ),
            Container(
              width: 35,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3F4652),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_filled, color: _orange, size: 22),
            ),
            const Icon(Icons.chat_bubble, color: Color(0xFF9EACBE), size: 20),
            const Icon(Icons.person, color: Color(0xFF9EACBE), size: 22),
          ],
        ),
      ),
    );
  }

  String _cleanError(Object? error) {
    final message = error.toString();
    return message
        .replaceAll(RegExp(r'exception:\s*', caseSensitive: false), '')
        .trim();
  }
}

class _SubjectSummary extends StatelessWidget {
  const _SubjectSummary({required this.detail});

  final MarkDetail detail;

  @override
  Widget build(BuildContext context) {
    final statusColor = detail.passed
        ? _MarkDetailScreenState._green
        : _MarkDetailScreenState._red;
    final statusBackground = detail.passed
        ? const Color(0xFFE1FAF0)
        : const Color(0xFFFFE2E7);
    final statusText = detail.passed ? 'Passed' : 'Not Passed';

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 3, color: statusColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        color: _MarkDetailScreenState._mutedText,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: detail.subjectCode,
                          style: const TextStyle(
                            color: _MarkDetailScreenState._titleText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        TextSpan(text: ' - ${detail.subjectName}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        height: 18,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: statusBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Class name: ${_displayClassName()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _MarkDetailScreenState._mutedText,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        color: _MarkDetailScreenState._mutedText,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        const TextSpan(text: 'Average: '),
                        TextSpan(
                          text: detail.average.toStringAsFixed(1),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _displayClassName() {
    final className = detail.className?.trim();
    if (className == null || className.isEmpty) {
      return 'N/A';
    }
    return className;
  }
}

class _GradeTable extends StatelessWidget {
  const _GradeTable({required this.items});

  final List<MarkDetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _GradeTableRow(
            gradeCategory: 'Grade category',
            gradeItem: 'Grade item',
            weight: 'Weight',
            value: 'Value',
            isHeader: true,
          ),
          for (var index = 0; index < items.length; index++)
            _GradeTableRow(
              gradeCategory: _categoryText(index),
              gradeItem: items[index].gradeItem,
              weight: _formatWeight(items[index].weight),
              value: items[index].value ?? '',
              isStatusRow: items[index].gradeItem.toLowerCase() == 'status',
            ),
        ],
      ),
    );
  }

  String _categoryText(int index) {
    if (index == 0) {
      return items[index].gradeCategory;
    }
    return items[index].gradeCategory == items[index - 1].gradeCategory
        ? ''
        : items[index].gradeCategory;
  }

  String _formatWeight(double? weight) {
    if (weight == null) {
      return '';
    }
    return '${weight.toStringAsFixed(1)} %';
  }
}

class _GradeTableRow extends StatelessWidget {
  const _GradeTableRow({
    required this.gradeCategory,
    required this.gradeItem,
    required this.weight,
    required this.value,
    this.isHeader = false,
    this.isStatusRow = false,
  });

  final String gradeCategory;
  final String gradeItem;
  final String weight;
  final String value;
  final bool isHeader;
  final bool isStatusRow;

  @override
  Widget build(BuildContext context) {
    final rowColor = isHeader
        ? _MarkDetailScreenState._headerTable
        : Colors.white;
    final textColor = isHeader ? Colors.white : const Color(0xFF394052);
    final fontWeight = isHeader ? FontWeight.w900 : FontWeight.w500;

    return Container(
      height: isHeader ? 30 : 31,
      decoration: BoxDecoration(
        color: rowColor,
        border: isHeader
            ? null
            : const Border(
                bottom: BorderSide(color: _MarkDetailScreenState._line),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TableCell(
            text: gradeCategory,
            flex: 31,
            textColor: textColor,
            fontWeight: fontWeight,
            isHeader: isHeader,
          ),
          _TableCell(
            text: gradeItem,
            flex: 31,
            textColor: textColor,
            fontWeight: fontWeight,
            isHeader: isHeader,
          ),
          _TableCell(
            text: weight,
            flex: 18,
            textColor: textColor,
            fontWeight: fontWeight,
            isHeader: isHeader,
            textAlign: TextAlign.center,
          ),
          _TableCell(
            text: value,
            flex: 20,
            textColor: isStatusRow ? _MarkDetailScreenState._green : textColor,
            fontWeight: isStatusRow ? FontWeight.w800 : fontWeight,
            isHeader: isHeader,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.text,
    required this.flex,
    required this.textColor,
    required this.fontWeight,
    required this.isHeader,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final int flex;
  final Color textColor;
  final FontWeight fontWeight;
  final bool isHeader;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: textAlign == TextAlign.center
            ? Alignment.center
            : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: isHeader
                  ? const Color(0x33FFFFFF)
                  : _MarkDetailScreenState._line,
            ),
          ),
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: textColor,
            fontSize: isHeader ? 8.5 : 8.2,
            height: 1.15,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF98A2B3), size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _MarkDetailScreenState._titleText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _MarkDetailScreenState._mutedText,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
