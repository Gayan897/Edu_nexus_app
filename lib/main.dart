import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'data/firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/app_provider.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase — connects to the shared SAMS Firestore database
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background message handler for Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Real-time Notification Service (Channels, permissions, listeners)
  await NotificationService.instance.init();

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const SAMSApp(),
    ),
  );
}

class SAMSApp extends StatelessWidget {
  const SAMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return MaterialApp(
          title: 'EduNexus – Smart Academic Management System',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: SAMSTheme.light,
          darkTheme: SAMSTheme.dark,
          home: provider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
        );
      },
    );
  }
}
