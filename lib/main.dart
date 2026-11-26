import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

// 1. دالة معالجة الإشعارات في الخلفية (سلايد 23)
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background Message ID: ${message.messageId}");
}

// 2. تحديث دالة main لتشمل تهيئة Firebase وطلب الإذن (سلايد 21 و 22)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // تسجيل معالج الخلفية
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  // السطر الخاص بطلب إذن الإشعارات من المستخدم (سلايد 21)
  final settings = await FirebaseMessaging.instance.requestPermission();
  debugPrint('Permission status: ${settings.authorizationStatus}');

  // جلب وطباعة الـ Token عشان نستخدمه في الاختبار (سلايد 25)
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('=========================================');
  debugPrint('FCM TOKEN: $token');
  debugPrint('=========================================');

  // الاستماع للإشعارات والتطبيق مفتوح (سلايد 24)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground Message Data: ${message.data}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6B),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D6B),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D6B),
            foregroundColor: Colors.white,
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}
