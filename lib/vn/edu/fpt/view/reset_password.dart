import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/api_client.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/forgot_password_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/notification_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/forgot_password_step_badge.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotPasswordService = ForgotPasswordService.instance;

  var _isSubmitting = false;
  var _obscureNewPassword = true;
  var _obscureConfirmPassword = true;

  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF7628);
  static const _canvas = Color(0xFFF6F7FB);
  static const _text = Color(0xFF1E2233);
  static const _muted = Color(0xFF7B8497);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await _forgotPasswordService.resetPassword(
        resetToken: widget.resetToken,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      await FirebaseAuth.instance.signOut();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;

      NotificationService.showMessage(message);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      final message = _errorMessage(e);
      if (e is ApiException && e.statusCode == 410) {
        await _handleExpiredResetToken(message);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleExpiredResetToken(String message) async {
    await FirebaseAuth.instance.signOut();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    if (!mounted) return;

    NotificationService.showError(
      message,
      duration: const Duration(seconds: 4),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (password.trim().isEmpty) {
      return 'Mật khẩu không được chỉ chứa khoảng trắng';
    }
    if (password.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu mới';
    }
    if (password != _newPasswordController.text) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error
        .toString()
        .replaceFirst(RegExp(r'^(Exception|FormatException):\s*'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Đổi mật khẩu'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11183A66),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ForgotPasswordStepBadge(currentStep: 3),
                    const SizedBox(height: 22),
                    const Text(
                      'Tạo mật khẩu mới',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mật khẩu mới cần có ít nhất 8 ký tự. Không chia sẻ mật khẩu cho người khác.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PasswordField(
                      controller: _newPasswordController,
                      labelText: 'Mật khẩu mới',
                      obscureText: _obscureNewPassword,
                      textInputAction: TextInputAction.next,
                      validator: _validateNewPassword,
                      onToggleObscure: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _PasswordField(
                      controller: _confirmPasswordController,
                      labelText: 'Nhập lại mật khẩu mới',
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      validator: _validateConfirmPassword,
                      onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
                      onToggleObscure: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
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
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSubmitting ? 'Đang đổi mật khẩu...' : 'Đổi mật khẩu',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
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
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.labelText,
    required this.obscureText,
    required this.onToggleObscure,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.newPassword],
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          onPressed: onToggleObscure,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F5FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: _ResetPasswordScreenState._orange,
          ),
        ),
      ),
    );
  }
}
