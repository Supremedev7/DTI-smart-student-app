import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart'; // <-- IMPORT SPLASH SCREEN

void main() async {
  // 1. Ensure Flutter bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Local Notifications
  await NotificationService.init();
  
  // 3. Safely load .env for the Groq API Key
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Cloud AI will fail without an API key.");
  }
  
  // 4. Initialize Hive local storage for settings, XP, and profile data
  await Hive.initFlutter();
  await Hive.openBox('userBox');

  // 5. Run the app
  runApp(const SmartStudentAssistant());
}

class SmartStudentAssistant extends StatelessWidget {
  const SmartStudentAssistant({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the entire app in a ValueListenableBuilder so it reacts to Theme changes dynamically
    return ValueListenableBuilder(
      valueListenable: Hive.box('userBox').listenable(),
      builder: (context, box, child) {
        
        // Determine the current theme mode from StorageService
        String themeStr = StorageService.getThemeMode();
        ThemeMode currentThemeMode = ThemeMode.system;
        if (themeStr == 'light') currentThemeMode = ThemeMode.light;
        if (themeStr == 'dark') currentThemeMode = ThemeMode.dark;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Smart Student Assistant",
          themeMode: currentThemeMode, 
          
          // --- LIGHT THEME ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            primaryColor: const Color(0xFF4F46E5),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF0F172A)),
              titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Color(0xFF334155)),
            ),
          ),
          
          // --- DARK THEME ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep slate background
            cardColor: const Color(0xFF1E293B), // Slightly lighter slate for cards
            primaryColor: const Color(0xFF6366F1), // Softer indigo for dark mode
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Color(0xFFCBD5E1)),
            ),
          ),
          
          // --- THE NEW ENTRY POINT ---
          home: const SplashScreen(), 
        );
      }
    );
  }
}