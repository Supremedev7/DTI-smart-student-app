import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final userBox = Hive.box("userBox");

  // --- THEME SETTINGS ---
  static String getThemeMode() => userBox.get("themeMode", defaultValue: "system");
  static void setThemeMode(String mode) => userBox.put("themeMode", mode);

  // --- AI Settings (Hybrid Mode) ---
  static bool isOnlineMode() => userBox.get("onlineMode", defaultValue: true);
  static void setOnlineMode(bool isOnline) => userBox.put("onlineMode", isOnline);

  // --- Language Settings (Translation) ---
  static String getLanguage() => userBox.get("language", defaultValue: "English");
  static void setLanguage(String lang) => userBox.put("language", lang);

  // --- Onboarding & Auth Flags ---
  static bool isOnboardingComplete() => userBox.get("onboardingComplete", defaultValue: false);
  static bool isLoggedIn() => userBox.get("isLoggedIn", defaultValue: false);

  // --- User Details ---
  static void saveUserDetails(String name, String email) {
    userBox.put("name", name);
    userBox.put("email", email);
    userBox.put("isLoggedIn", true);
    userBox.put("onboardingComplete", true);
  }

  static String getUserName() => userBox.get("name", defaultValue: "Student");
  static String getUserEmail() => userBox.get("email", defaultValue: "student@school.com");
  static void logout() => userBox.put("isLoggedIn", false);

  // --- Notification Settings ---
  static bool getStudyReminders() => userBox.get("studyReminders", defaultValue: false);
  static void setStudyReminders(bool value) => userBox.put("studyReminders", value);

  // ==========================================
  // --- GAMIFICATION (XP, STREAKS & HEATMAP) ---
  // ==========================================

  // NEW: Tracks how much XP was earned on specific dates for the Heatmap
  static void addDailyXP(int xp) {
    String today = DateTime.now().toIso8601String().split('T')[0];
    Map<dynamic, dynamic> rawMap = userBox.get("dailyXP", defaultValue: {});
    Map<String, int> dailyMap = Map<String, int>.from(rawMap);
    
    dailyMap[today] = (dailyMap[today] ?? 0) + xp;
    userBox.put("dailyXP", dailyMap);
  }

  // UPDATED: Now also logs to the daily tracker
  static void addXP(int xp) {
    userBox.put("xp", getXP() + xp);
    addDailyXP(xp); 
  }
  
  static int getXP() => userBox.get("xp", defaultValue: 0);
  
  static int getStreak() => userBox.get("streak", defaultValue: 0);

  // NEW: Retrieves the data formatted exactly how the flutter_heatmap_calendar package wants it
  static Map<DateTime, int> getHeatmapData() {
    Map<dynamic, dynamic> rawMap = userBox.get("dailyXP", defaultValue: {});
    Map<DateTime, int> heatmapData = {};
    
    rawMap.forEach((key, value) {
      try {
        heatmapData[DateTime.parse(key.toString())] = value as int;
      } catch (e) {
        // Ignore parsing errors for malformed dates
      }
    });
    return heatmapData;
  }

  // Real date-based logic so the user can only extend their streak once per day
  static void updateStreak() {
    String today = DateTime.now().toIso8601String().split('T')[0];
    String lastStudyDate = userBox.get("lastStudyDate", defaultValue: "");

    if (lastStudyDate == today) {
      return; // The user has already studied today, do not increment again.
    }

    if (lastStudyDate.isNotEmpty) {
      DateTime lastDate = DateTime.parse(lastStudyDate);
      DateTime todayDate = DateTime.parse(today);
      int difference = todayDate.difference(lastDate).inDays;

      if (difference == 1) {
        userBox.put("streak", getStreak() + 1); // Streak continues!
      } else if (difference > 1) {
        userBox.put("streak", 1); // Streak broken, reset to 1
      }
    } else {
       userBox.put("streak", 1); // First day ever
    }
    
    userBox.put("lastStudyDate", today);
  }

  // --- Stats Tracking ---
  static void incrementQuizzes() => userBox.put("quizzes", getQuizzesCompleted() + 1);
  static int getQuizzesCompleted() => userBox.get("quizzes", defaultValue: 0);
  static void incrementPdfs() => userBox.put("pdfs", getPdfsStored() + 1);
  static int getPdfsStored() => userBox.get("pdfs", defaultValue: 0);

  // --- RECENT ACTIVITY TRACKER ---
  static void addRecentActivity(String title, String subtitle, String iconType) {
    List<dynamic> currentList = userBox.get("recentActivities", defaultValue: []);
    List<Map<String, dynamic>> activities = List<Map<String, dynamic>>.from(
        currentList.map((e) => Map<String, dynamic>.from(e as Map)));

    activities.insert(0, {"title": title, "subtitle": subtitle, "iconType": iconType});
    if (activities.length > 5) activities = activities.sublist(0, 5);
    userBox.put("recentActivities", activities);
  }

  static List<Map<String, dynamic>> getRecentActivities() {
    List<dynamic> currentList = userBox.get("recentActivities", defaultValue: []);
    return List<Map<String, dynamic>>.from(currentList.map((e) => Map<String, dynamic>.from(e as Map)));
  }

  // ==========================================
  // --- MY LIBRARY SETTINGS (WITH CASTING FIX) ---
  // ==========================================

  static void saveToLibrary(String type, String title, dynamic content) {
    List<dynamic> items = userBox.get("library_$type", defaultValue: []);
    items.insert(0, {
      "title": title,
      "content": content,
      "date": DateTime.now().toIso8601String(),
    });
    userBox.put("library_$type", items);
  }

  // DEEP CASTING FIX: Safely converts Hive dynamic maps back to UI maps
  static List<Map<String, dynamic>> getLibraryItems(String type) {
    List<dynamic> rawList = userBox.get("library_$type", defaultValue: []);
    
    return rawList.map((item) {
      Map<String, dynamic> formattedItem = {};
      if (item is Map) {
        item.forEach((key, value) {
          formattedItem[key.toString()] = value;
        });
      }

      // If the content is an array (like a Quiz or Flashcard list), cast the inner elements safely
      if (formattedItem["content"] is List) {
        List<dynamic> rawContentList = formattedItem["content"];
        List<Map<String, dynamic>> safeContentList = [];
        
        for (var element in rawContentList) {
          if (element is Map) {
            Map<String, dynamic> safeElement = {};
            element.forEach((k, v) {
              // Special fix for Quiz options array
              if (k.toString() == "options" && v is List) {
                safeElement[k.toString()] = v.map((e) => e.toString()).toList();
              } else {
                safeElement[k.toString()] = v;
              }
            });
            safeContentList.add(safeElement);
          }
        }
        formattedItem["content"] = safeContentList; // Replace with safe list
      }

      return formattedItem;
    }).toList();
  }

  static void deleteLibraryItem(String type, int index) {
    List<dynamic> items = userBox.get("library_$type", defaultValue: []);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      userBox.put("library_$type", items);
    }
  }
}