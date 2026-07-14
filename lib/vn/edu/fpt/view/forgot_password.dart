import 'package:flutter/material.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/firebase_phone_auth_service.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/otp_screen.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/widgets/forgot_password_step_badge.dart';

String normalizeVietnamPhone(String phone) {
  final value = phone.replaceAll(RegExp(r'\s+'), '');

  if (value.startsWith('+84')) {
    return value;
  }

  if (value.startsWith('0')) {
    return '+84${value.substring(1)}';
  }

  return '+84$value';
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController(text: '+84 969 722 750');
  final FirebasePhoneAuthService phoneAuthService =
      FirebasePhoneAuthService.instance;

  String? verificationId;
  bool isSending = false;

  static const _navy = Color(0xFF183A66);
  static const _orange = Color(0xFFFF7628);
  static const _canvas = Color(0xFFF6F7FB);
  static const _text = Color(0xFF1E2233);

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSending = true;
    });

    final displayPhone = phoneController.text.trim();
    final firebasePhone = normalizeVietnamPhone(displayPhone);

    await phoneAuthService.sendOtp(
      phoneNumber: firebasePhone,
      onCodeSent: (id) {
        if (!mounted) return;

        setState(() {
          verificationId = id;
          isSending = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpScreen(verificationId: id, phoneNumber: displayPhone),
          ),
        );
      },
      onError: (message) {
        if (!mounted) return;

        setState(() {
          isSending = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Quên mật khẩu'),
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
                    const ForgotPasswordStepBadge(currentStep: 1),
                    const SizedBox(height: 22),
                    const Text(
                      'Xác minh số điện thoại',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: phoneController,
                      readOnly: true,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone_android_outlined),
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
                        if ((value ?? '').trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: isSending ? null : sendOtp,
                      icon: isSending
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
                      label: Text(isSending ? 'Đang gửi OTP...' : 'Gửi OTP'),
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
