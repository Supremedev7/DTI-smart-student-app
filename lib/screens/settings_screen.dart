import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../utils/app_strings.dart';
import 'onboarding_screen.dart';
import 'theme_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDownloaded = true;

  @override
  void initState() {
    super.initState();
    _checkLanguageStatus(StorageService.getLanguage());
  }

  Future<void> _checkLanguageStatus(String lang) async {
    bool status = await TranslationService.isLanguageDownloaded(lang);
    if (mounted) setState(() => isDownloaded = status);
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 24),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.5), letterSpacing: 1.2)
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> children, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppStrings.get("settings"), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('userBox').listenable(),
        builder: (context, box, child) {
          String currentLang = StorageService.getLanguage();
          String currentTheme = StorageService.getThemeMode();
          bool isOnline = StorageService.isOnlineMode();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            children: [
              // --- AI CONNECTIVITY ---
              _buildSectionHeader("AI Connectivity", textColor),
              _buildSettingGroup([
                SwitchListTile(
                  secondary: Icon(isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: isOnline ? const Color(0xFF10B981) : Colors.grey),
                  title: const Text("Cloud AI Mode", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isOnline ? "Using Groq for advanced generation" : "Using pure-Dart Statistical NLP", style: const TextStyle(fontSize: 12)),
                  value: isOnline,
                  onChanged: (val) => StorageService.setOnlineMode(val),
                ),
                
                const Divider(height: 1),
                
                // --- THE NEW STATISTICAL ENGINE INFO ---
                const ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(Icons.bolt_rounded, color: Color(0xFF8B5CF6), size: 32),
                  title: Text("Statistical Offline Engine", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Built-in. Instant vector math. Zero downloads required.", style: TextStyle(fontSize: 12)),
                  trailing: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)), // Always ready!
                ),
              ], cardColor),

              // --- NOTIFICATIONS ---
              _buildSectionHeader(AppStrings.get("notifications"), textColor),
              _buildSettingGroup([
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B)),
                  title: Text(AppStrings.get("study_reminders"), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppStrings.get("reminders_sub"), style: const TextStyle(fontSize: 12)),
                  value: StorageService.getStudyReminders(),
                  onChanged: (val) async {
                    StorageService.setStudyReminders(val);
                    if (val) {
                      await NotificationService.scheduleDailyReminder();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Daily study reminders set for 6:00 PM"))
                        );
                      }
                    } else {
                      await NotificationService.cancelAll();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Study reminders turned off"))
                        );
                      }
                    }
                    setState(() {}); // Force UI update for the test button
                  },
                ),
                
                // TEST NOTIFICATION BUTTON (Only visible if reminders are ON)
                if (StorageService.getStudyReminders()) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.send_to_mobile_rounded, color: Color(0xFF4F46E5)),
                    title: const Text("Test Notification System", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Sends a test alert to your phone immediately", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      await NotificationService.testNotification();
                    },
                  ),
                ]
              ], cardColor),

              // --- LANGUAGE ---
              _buildSectionHeader("Language", textColor),
              _buildSettingGroup([
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Color(0xFF4F46E5)),
                  title: Text(AppStrings.get("study_language"), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(currentLang, style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                  onTap: () => _showLanguagePicker(currentLang),
                ),
              ], cardColor),

              // --- THEME ---
              _buildSectionHeader(AppStrings.get("theme"), textColor),
              _buildSettingGroup([
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6)),
                  title: Text(AppStrings.get("theme"), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(currentTheme == 'system' ? AppStrings.get("system_default") : currentTheme),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemeScreen())),
                ),
              ], cardColor),

              // --- ACCOUNT & DATA ---
              _buildSectionHeader(AppStrings.get("account"), textColor),
              _buildSettingGroup([
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                  title: Text(AppStrings.get("clear_data"), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => _confirmClearData(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.grey),
                  title: Text(AppStrings.get("logout"), style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await NotificationService.cancelAll(); // Stop notifications on logout
                    StorageService.logout();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()), (r) => false);
                    }
                  },
                ),
              ], cardColor),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _showLanguagePicker(String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ["English", "Hindi", "Telugu", "Tamil"].map((l) => ListTile(
            title: Text(l, textAlign: TextAlign.center, style: TextStyle(fontWeight: l == current ? FontWeight.bold : FontWeight.normal)),
            onTap: () {
              StorageService.setLanguage(l);
              _checkLanguageStatus(l);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get("confirm")),
        content: Text(AppStrings.get("clear_data_desc")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.get("cancel"))),
          TextButton(
            onPressed: () async {
              await NotificationService.cancelAll(); // Clear alarms
              await Hive.box('userBox').clear(); // Wipe database
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()), (r) => false);
              }
            }, 
            child: const Text("Reset App", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}