import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:myfschoolse1911/firebase_options.dart';
import 'package:myfschoolse1911/vn/edu/fpt/view/login.dart';
import 'package:myfschoolse1911/vn/edu/fpt/service/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: notificationNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'My FSchool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}