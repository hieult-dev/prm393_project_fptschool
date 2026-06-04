import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfschoolse1911/main.dart';

void main() {
  testWidgets('Login screen renders form controls', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Chào mừng quý phụ huynh'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsWidgets);
    expect(find.text('Lưu thông tin đăng nhập'), findsNothing);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Hoặc đăng nhập bằng'), findsNothing);
    expect(find.text('FEID'), findsNothing);
    expect(find.textContaining('Copyright FPT Schools'), findsOneWidget);
    expect(find.byIcon(Icons.phone_android_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('Login screen validates required inputs', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Vui lòng nhập tài khoản'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });
}
