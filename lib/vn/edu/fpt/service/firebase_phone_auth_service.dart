import 'package:firebase_auth/firebase_auth.dart';

class FirebasePhoneAuthService {
  FirebasePhoneAuthService._();

  static final FirebasePhoneAuthService instance = FirebasePhoneAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android có thể tự động xác minh trong một số trường hợp.
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_sendOtpMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (_) {
      onError('Không thể gửi OTP. Vui lòng thử lại.');
    }
  }

  String _sendOtpMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ';
      case 'too-many-requests':
        return 'Bạn đã yêu cầu OTP quá nhiều lần';
      case 'quota-exceeded':
        return 'Đã vượt giới hạn gửi SMS';
      default:
        return error.message ?? 'Không thể gửi OTP';
    }
  }

  Future<String> verifyOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.trim(),
      );

      final result = await _auth.signInWithCredential(credential);

      final idToken = await result.user?.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không lấy được Firebase ID Token');
      }

      return idToken;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Mã OTP không chính xác');

        case 'session-expired':
          throw Exception('Phiên OTP đã hết hạn');

        default:
          throw Exception(e.message ?? 'Không thể xác minh OTP');
      }
    }
  }
}
