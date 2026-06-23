import 'package:flutter/material.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _accountController;
  TextEditingController? _passwordController;

  bool _obscurePassword = true;

  static const _orange = Color(0xFFFF7628);
  static const _primaryText = Color(0xFF1E2233);
  static const _fieldFill = Color(0xFFF7F5FC);
  static const _buttonFill = Color(0xFFFFB98F);

  TextEditingController get _accountTextController {
    return _accountController ??= TextEditingController();
  }

  TextEditingController get _passwordTextController {
    return _passwordController ??= TextEditingController();
  }

  @override
  void dispose() {
    _accountController?.dispose();
    _passwordController?.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 54, 18, 26),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/images/logo_fpt_edu.png',
                                  width: 345,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 34),
                              const _FieldLabel('Tài khoản'),
                              const SizedBox(height: 8),
                              _LoginTextField(
                                controller: _accountTextController,
                                hintText: 'Số điện thoại',
                                prefixIcon: const Icon(
                                  Icons.phone_android_outlined,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Vui lòng nhập tài khoản';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const _FieldLabel('Mật khẩu'),
                              const SizedBox(height: 8),
                              _LoginTextField(
                                controller: _passwordTextController,
                                hintText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Hiện mật khẩu'
                                      : 'Ẩn mật khẩu',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _primaryText,
                                    size: 21,
                                  ),

                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: _orange,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  child: const Text('Quên mật khẩu ?'),
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 52,
                                child: FilledButton(
                                  onPressed: _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _buttonFill,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Đăng nhập'),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 36),
                              const Text(
                                'Phiên bản 2.2.0.0\nCopyright FPT Schools',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF65709A),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: _LoginScreenState._primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFAAB0C8),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : IconTheme(
                data: const IconThemeData(
                  color: _LoginScreenState._orange,
                  size: 21,
                ),
                child: prefixIcon!,
              ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _LoginScreenState._fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _LoginScreenState._orange),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _LoginScreenState._primaryText,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
