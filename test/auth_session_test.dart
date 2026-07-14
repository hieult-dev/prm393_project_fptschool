import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/auth_session.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('stores access and refresh tokens together', () async {
    await AuthSession.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    expect(await AuthSession.readAccessToken(), 'access-token');
    expect(await AuthSession.readRefreshToken(), 'refresh-token');
    expect(await AuthSession.authorizedHeaders(), <String, String>{
      'Authorization': 'Bearer access-token',
    });
  });

  test('clear removes both tokens', () async {
    await AuthSession.saveTokens(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );

    await AuthSession.clear();

    expect(await AuthSession.readAccessToken(), isNull);
    expect(await AuthSession.readRefreshToken(), isNull);
    await expectLater(
      AuthSession.authorizedHeaders(),
      throwsA(isA<SessionExpiredException>()),
    );
  });
}
