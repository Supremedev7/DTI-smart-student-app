import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for Flutter
  await Hive.initFlutter();
  await Hive.openBox('userBox');

  runApp(const SmartStudentAssistant());
}

class SmartStudentAssistant extends StatelessWidget {
  const SmartStudentAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if the user has already onboarded and logged in
    Widget initialScreen = const OnboardingScreen();
    if (StorageService.isOnboardingComplete() && StorageService.isLoggedIn()) {
      initialScreen = const MainNavigation();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Student Assistant",
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      home: initialScreen,
    );
  }
}