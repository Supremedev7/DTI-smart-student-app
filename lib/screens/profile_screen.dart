import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF8FAFC);
    final primaryColor = const Color(0xFF8B5CF6); // Violet Theme for Profile

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              // TODO: Settings screen or Logout functionality
            },
          )
        ],
      ),
      // --- VALUE LISTENABLE BUILDER MAKES THE PROFILE REACTIVE ---
      body: ValueListenableBuilder(
        valueListenable: Hive.box('userBox').listenable(),
        builder: (context, box, child) {
          // 1. Fetch live data
          final name = StorageService.getUserName();
          final email = StorageService.getUserEmail();
          final xp = StorageService.getXP();
          final streak = StorageService.getStreak();
          final quizzes = StorageService.getQuizzesCompleted();
          final pdfs = StorageService.getPdfsStored();
          final recents = StorageService.getRecentActivities();

          // 2. Calculate Gamification logic
          int currentLevel = (xp / 100).floor() + 1;
          int xpForNextLevel = currentLevel * 100;
          double levelProgress = (xp % 100) / 100;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Profile Card ---
                  _buildProfileHeader(primaryColor, name, email),
                  const SizedBox(height: 24),

                  // --- Gamification Section (Streak & Level) ---
                  _buildGamificationCard(primaryColor, currentLevel, xp, xpForNextLevel, levelProgress, streak),
                  const SizedBox(height: 32),

                  // --- Stats Grid ---
                  const Text(
                    "My Stats",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Quizzes Taken", quizzes.toString(), Icons.quiz_rounded, const Color(0xFFEC4899))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard("Saved PDFs", pdfs.toString(), Icons.picture_as_pdf_rounded, const Color(0xFFEF4444))),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Recent Activity ---
                  const Text(
                    "Recent Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  
                  if (recents.isEmpty)
                     Padding(
                       padding: const EdgeInsets.symmetric(vertical: 20.0),
                       child: Center(
                         child: Text("No activity yet. Go study!", style: TextStyle(color: Colors.grey.shade500)),
                       ),
                     )
                  else
                    ...recents.map((item) {
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
                        child: _buildActivityItem(item["title"] ?? "Unknown", item["subtitle"] ?? "", icon, color),
                      );
                    }),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Color themeColor, String name, String email) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: themeColor.withOpacity(0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: themeColor.withOpacity(0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: themeColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            email.isEmpty ? "No email provided" : email,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard(Color themeColor, int currentLevel, int xp, int xpForNextLevel, double levelProgress, int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [themeColor, const Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CURRENT LEVEL", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Lv. $currentLevel", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, height: 1)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 24),
                    const SizedBox(width: 8),
                    Text("$streak Day Streak", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$xp XP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text("$xpForNextLevel XP", style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ),
    );
  }
}