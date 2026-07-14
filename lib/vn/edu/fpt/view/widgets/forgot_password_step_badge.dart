import 'package:flutter/material.dart';

class ForgotPasswordStepBadge extends StatelessWidget {
  const ForgotPasswordStepBadge({super.key, required this.currentStep});

  final int currentStep;

  static const _orange = Color(0xFFFF7628);
  static const _navy = Color(0xFF183A66);
  static const _muted = Color(0xFF7B8497);
  static const _line = Color(0xFFE6E9F2);
  static const _steps = <String>['SĐT', 'OTP', 'Mật khẩu'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _steps.length; index++) ...[
            _StepItem(
              number: index + 1,
              label: _steps[index],
              isActive: currentStep == index + 1,
              isDone: currentStep > index + 1,
            ),
            if (index != _steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: currentStep > index + 1 ? _orange : _line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isActive || isDone
        ? ForgotPasswordStepBadge._orange
        : ForgotPasswordStepBadge._muted;
    final background = isActive || isDone
        ? const Color(0xFFFFEFE6)
        : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.4),
          ),
          child: isDone
              ? Icon(Icons.check_rounded, size: 16, color: color)
              : Text(
                  '$number',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? ForgotPasswordStepBadge._navy : color,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
