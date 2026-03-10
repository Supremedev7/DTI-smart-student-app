import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final userBox = Hive.box("userBox");

  // --- Onboarding & Auth Flags ---
  static bool isOnboardingComplete() {
    return userBox.get("onboardingComplete", defaultValue: false);
  }

  static bool isLoggedIn() {
    return userBox.get("isLoggedIn", defaultValue: false);
  }

  // --- User Details ---
  static void saveUserDetails(String name, String email) {
    userBox.put("name", name);
    userBox.put("email", email);
    userBox.put("isLoggedIn", true);
    userBox.put("onboardingComplete", true);
  }

  static String getUserName() {
    return userBox.get("name", defaultValue: "Student");
  }

  static String getUserEmail() {
    return userBox.get("email", defaultValue: "student@school.com");
  }

  static void logout() {
    userBox.put("isLoggedIn", false);
  }

  // --- Gamification (XP & Streaks) ---
  static void addXP(int xp) {
    int current = userBox.get("xp", defaultValue: 0);
    userBox.put("xp", current + xp);
  }

  static int getXP() {
    return userBox.get("xp", defaultValue: 0);
  }

  static void increaseStreak() {
    int streak = userBox.get("streak", defaultValue: 1);
    userBox.put("streak", streak + 1);
  }

  static int getStreak() {
    return userBox.get("streak", defaultValue: 1);
  }

  // --- Stats Tracking ---
  static void incrementQuizzes() {
    int current = userBox.get("quizzes", defaultValue: 0);
    userBox.put("quizzes", current + 1);
  }

  static int getQuizzesCompleted() {
    return userBox.get("quizzes", defaultValue: 0);
  }

  static void incrementPdfs() {
    int current = userBox.get("pdfs", defaultValue: 0);
    userBox.put("pdfs", current + 1);
  }

  static int getPdfsStored() {
    return userBox.get("pdfs", defaultValue: 0);
  }

  // --- RECENT ACTIVITY TRACKER ---
  static void addRecentActivity(String title, String subtitle, String iconType) {
    // Retrieve current list
    List<dynamic> currentList = userBox.get("recentActivities", defaultValue: []);
    
    // Convert to a strongly typed list of maps
    List<Map<String, dynamic>> activities = List<Map<String, dynamic>>.from(
        currentList.map((e) => Map<String, dynamic>.from(e as Map)));

    // Insert new activity at the top
    activities.insert(0, {
      "title": title,
      "subtitle": subtitle,
      "iconType": iconType,
    });

    // Keep only the 5 most recent activities so it doesn't clutter
    if (activities.length > 5) {
      activities = activities.sublist(0, 5);
    }
    
    // Save back to Hive
    userBox.put("recentActivities", activities);
  }

  static List<Map<String, dynamic>> getRecentActivities() {
    List<dynamic> currentList = userBox.get("recentActivities", defaultValue: []);
    return List<Map<String, dynamic>>.from(
        currentList.map((e) => Map<String, dynamic>.from(e as Map)));
  }
}