import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/vn/edu/fpt/model/verify_phone_response.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/forgot_password.dart';

void main() {
  test('normalizes Vietnamese phone numbers for Firebase OTP', () {
    expect(normalizeVietnamPhone('0969722750'), '+84969722750');
    expect(normalizeVietnamPhone(' 096 972 2750 '), '+84969722750');
    expect(normalizeVietnamPhone('+84969722750'), '+84969722750');
    expect(normalizeVietnamPhone('+84 969 722 750'), '+84969722750');
    expect(normalizeVietnamPhone('969722750'), '+84969722750');
  });

  test('parses verify phone response', () {
    final response = VerifyPhoneResponse.fromJson(<String, dynamic>{
      'resetToken': 'reset-token',
      'expiresInSeconds': 600,
    });

    expect(response.resetToken, 'reset-token');
    expect(response.expiresInSeconds, 600);
  });
}
