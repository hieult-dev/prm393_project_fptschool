import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/firebase_phone_auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/forgot_password_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/reset_password.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/forgot_password_step_badge.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  final String verificationId;
  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController(text: '153204');
  final _phoneAuthService = FirebasePhoneAuthService.instance;
  final _forgotPasswordService = ForgotPasswordService.instance;

  var _isVerifying = false;

  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF7628);
  static const _canvas = Color(0xFFF6F7FB);
  static const _text = Color(0xFF1E2233);
  static const _muted = Color(0xFF7B8497);

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final firebaseIdToken = await _phoneAuthService.verifyOtp(
        verificationId: widget.verificationId,
        otp: _otpController.text,
      );
      final result = await _forgotPasswordService.verifyPhone(firebaseIdToken);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordScreen(resetToken: result.resetToken),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e
          .toString()
          .replaceFirst(RegExp(r'^Exception:\s*'), '')
          .trim();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Nhập mã OTP'),
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
                    const ForgotPasswordStepBadge(currentStep: 2),
                    const SizedBox(height: 22),
                    const Text(
                      'Xác nhận OTP',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nhập mã OTP đã gửi tới ${widget.phoneNumber}.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onFieldSubmitted: (_) =>
                          _isVerifying ? null : _verifyOtp(),
                      decoration: InputDecoration(
                        labelText: 'Mã OTP',
                        hintText: '153204',
                        prefixIcon: const Icon(Icons.password_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF7F5FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _orange),
                        ),
                      ),
                      validator: (value) {
                        final otp = (value ?? '').trim();
                        if (otp.isEmpty) {
                          return 'Vui lòng nhập mã OTP';
                        }
                        if (otp.length < 6) {
                          return 'Mã OTP phải có 6 chữ số';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isVerifying ? null : _verifyOtp,
                      icon: _isVerifying
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
                          : const Icon(Icons.verified_rounded),
                      label: Text(
                        _isVerifying ? 'Đang xác minh...' : 'Xác minh OTP',
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
