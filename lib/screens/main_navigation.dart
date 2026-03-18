import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'home_screen.dart';
import 'pdf_summarizer_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'timer_screen.dart'; // <-- IMPORT THE NEW TIMER SCREEN
import 'profile_screen.dart';
import '../utils/app_strings.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  // Add the TimerScreen to the pages list (index 4)
  final List<Widget> pages = [
    const HomeScreen(),
    const PdfSummarizerScreen(),
    const FlashcardScreen(),
    const QuizScreen(),
    const TimerScreen(), // <-- ADDED TIMER SCREEN
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final unselectedColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    return ValueListenableBuilder(
      valueListenable: Hive.box('userBox').listenable(),
      builder: (context, box, child) {
        return Scaffold(
          backgroundColor: bgColor, 
          body: IndexedStack(
            index: currentIndex,
            children: pages,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor, 
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.06), 
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                // Wrap SalomonBottomBar in SingleChildScrollView to prevent overflow 
                // on smaller devices since we now have 6 tabs!
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SalomonBottomBar(
                    currentIndex: currentIndex,
                    onTap: (i) {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    items: [
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.home_rounded),
                        title: Text(AppStrings.get("nav_home"), style: const TextStyle(fontWeight: FontWeight.w600)),
                        selectedColor: const Color(0xFF4F46E5), 
                        unselectedColor: unselectedColor,
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.document_scanner_rounded),
                        title: Text(AppStrings.get("nav_summary"), style: const TextStyle(fontWeight: FontWeight.w600)),
                        selectedColor: const Color(0xFF10B981), 
                        unselectedColor: unselectedColor,
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.style_rounded),
                        title: Text(AppStrings.get("nav_cards"), style: const TextStyle(fontWeight: FontWeight.w600)),
                        selectedColor: const Color(0xFFF59E0B), 
                        unselectedColor: unselectedColor,
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.quiz_rounded),
                        title: Text(AppStrings.get("nav_quiz"), style: const TextStyle(fontWeight: FontWeight.w600)),
                        selectedColor: const Color(0xFFEC4899), 
                        unselectedColor: unselectedColor,
                      ),
                      // --- NEW TIMER NAV ITEM ---
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.timer_rounded),
                        title: const Text("Focus", style: TextStyle(fontWeight: FontWeight.w600)),
                        selectedColor: const Color(0xFFEF4444), // Pomodoro Tomato Red
                        unselectedColor: unselectedColor,
                      ),
                      SalomonBottomBarItem(
                        icon: const Icon(Icons.person_rounded),
                        title: Text(AppStrings.get("nav_profile"), style: const TextStyle(fontWeight: FontWeight.w600)),
                        selectedColor: const Color(0xFF8B5CF6), 
                        unselectedColor: unselectedColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}