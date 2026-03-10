import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'home_screen.dart';
import 'pdf_summarizer_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  // We keep the instances of the screens here
  final List<Widget> pages = [
    const HomeScreen(),
    const PdfSummarizerScreen(),
    const FlashcardScreen(),
    const QuizScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matching the modern soft slate background
      backgroundColor: const Color(0xFFF8FAFC),
      
      // IndexedStack preserves the state of the screens! 
      // (e.g., your generated flashcards won't disappear when you change tabs)
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      // Floating bottom navigation bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), // Pill shape capsule
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
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
                
                // Home - Indigo
                SalomonBottomBarItem(
                  icon: const Icon(Icons.home_rounded),
                  title: const Text("Home", style: TextStyle(fontWeight: FontWeight.w600)),
                  selectedColor: const Color(0xFF4F46E5), 
                  unselectedColor: Colors.grey.shade400,
                ),

                // Summarizer - Emerald Green
                SalomonBottomBarItem(
                  icon: const Icon(Icons.document_scanner_rounded),
                  title: const Text("Summary", style: TextStyle(fontWeight: FontWeight.w600)),
                  selectedColor: const Color(0xFF10B981), 
                  unselectedColor: Colors.grey.shade400,
                ),

                // Flashcards - Amber Yellow
                SalomonBottomBarItem(
                  icon: const Icon(Icons.style_rounded),
                  title: const Text("Cards", style: TextStyle(fontWeight: FontWeight.w600)),
                  selectedColor: const Color(0xFFF59E0B), 
                  unselectedColor: Colors.grey.shade400,
                ),

                // Quiz - Pink
                SalomonBottomBarItem(
                  icon: const Icon(Icons.quiz_rounded),
                  title: const Text("Quiz", style: TextStyle(fontWeight: FontWeight.w600)),
                  selectedColor: const Color(0xFFEC4899), 
                  unselectedColor: Colors.grey.shade400,
                ),

                // Profile - Violet
                SalomonBottomBarItem(
                  icon: const Icon(Icons.person_rounded),
                  title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w600)),
                  selectedColor: const Color(0xFF8B5CF6), 
                  unselectedColor: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}