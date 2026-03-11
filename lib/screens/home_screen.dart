import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../utils/app_strings.dart';

import 'pdf_summarizer_screen.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dynamically grab the theme colors and check if dark mode is active
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ValueListenableBuilder(
      valueListenable: Hive.box('userBox').listenable(),
      builder: (context, box, widget) {
        String name = StorageService.getUserName();
        final recents = StorageService.getRecentActivities();

        return Scaffold(
          backgroundColor: bgColor, // <-- DYNAMIC BACKGROUND
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(name, cardColor, titleColor, subtitleColor),
                  const SizedBox(height: 32),
                  _buildHeroCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(AppStrings.get("quick_tools"), titleColor),
                  const SizedBox(height: 16),
                  _buildToolsGrid(context, cardColor, isDark),
                  const SizedBox(height: 32),
                  _buildSectionTitle(AppStrings.get("recent_activity"), titleColor),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(recents, cardColor, titleColor, subtitleColor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String name, Color cardColor, Color titleColor, Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppStrings.get("hello")} $name 👋",
              style: TextStyle(
                fontSize: 16,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.get("ready_to_learn"),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor, // <-- DYNAMIC CARD COLOR
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 28),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(AppStrings.get("pro_feature"), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.get("hero_title"), style: const TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(AppStrings.get("hero_subtitle"), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context, Color cardColor, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF334155);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildToolCard(context, AppStrings.get("nav_summary"), Icons.document_scanner_rounded, const Color(0xFF10B981), cardColor, textColor, const PdfSummarizerScreen()),
        _buildToolCard(context, AppStrings.get("flashcards"), Icons.style_rounded, const Color(0xFFF59E0B), cardColor, textColor, const FlashcardScreen()),
        _buildToolCard(context, AppStrings.get("nav_quiz"), Icons.quiz_rounded, const Color(0xFFEC4899), cardColor, textColor, const QuizScreen()),
      ],
    );
  }

  Widget _buildToolCard(BuildContext context, String title, IconData icon, Color iconColor, Color cardColor, Color textColor, Widget destination) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor, // <-- DYNAMIC CARD COLOR
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const Spacer(),
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(List<Map<String, dynamic>> recents, Color cardColor, Color titleColor, Color subtitleColor) {
    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            AppStrings.get("no_recent_activity"),
            style: TextStyle(color: subtitleColor),
          ),
        ),
      );
    }

    return Column(
      children: recents.map((item) {
        IconData icon = Icons.check_circle_rounded;
        Color color = const Color(0xFF4F46E5);

        if (item["iconType"] == "summary") {
          icon = Icons.document_scanner_rounded;
          color = const Color(0xFF10B981);
        } else if (item["iconType"] == "flashcard") {
          icon = Icons.style_rounded;
          color = const Color(0xFFF59E0B);
        } else if (item["iconType"] == "quiz") {
          icon = Icons.quiz_rounded;
          color = const Color(0xFFEC4899);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildRecentItem(
            item["title"] ?? "Unknown", 
            item["subtitle"] ?? "", 
            icon, 
            color,
            cardColor,
            titleColor,
            subtitleColor
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentItem(String title, String subtitle, IconData icon, Color iconColor, Color cardColor, Color titleColor, Color subtitleColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor, // <-- DYNAMIC CARD COLOR
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor)),
        subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 13)),
        trailing: Icon(Icons.chevron_right_rounded, color: subtitleColor),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color titleColor) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor, letterSpacing: 0.2));
  }
}