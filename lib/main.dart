import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // ✅ Tambah import register
import 'screens/main_screen.dart';
import 'screens/sungai_screen.dart';
import 'screens/notification_screen.dart';

import 'utils/constants.dart';
import 'utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp();

  // Setup background notification handler
  FirebaseMessaging.onBackgroundMessage(NotificationService.backgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService.initializeFCM();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Early Flood Warning',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(), // ✅ Tambah route
        '/pilih-sungai': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return SungaiScreen(arguments: args);
        },
        '/dashboard': (context) {
          final sungai = ModalRoute.of(context)!.settings.arguments as String;
          return MainScreen(namaSungai: sungai);
        },
        '/notifikasi': (context) {
          return const NotificationScreen(); // Argumen diambil di dalam screen
        },
      },
    );
  }
}
