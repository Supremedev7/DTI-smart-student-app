import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../utils/app_strings.dart';
import 'onboarding_screen.dart';
import 'theme_screen.dart'; // Ensure this is imported

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDownloaded = true;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkLanguageStatus(StorageService.getLanguage());
  }

  Future<void> _checkLanguageStatus(String lang) async {
    bool status = await TranslationService.isLanguageDownloaded(lang);
    if (mounted) setState(() => isDownloaded = status);
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 24),
      child: Text(
        title.toUpperCase(), 
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.5), letterSpacing: 1.2)
      ),
    );
  }

  // Helper for Setting Containers
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
          bool isOnline = StorageService.isOnlineMode();
          String currentLang = StorageService.getLanguage();
          String currentTheme = StorageService.getThemeMode();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            children: [
              // --- AI & LANGUAGE ---
              _buildSectionHeader(AppStrings.get("generation_mode"), textColor),
              _buildSettingGroup([
                SwitchListTile(
                  title: Text(AppStrings.get("cloud_ai"), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isOnline ? AppStrings.get("cloud_ai_sub") : AppStrings.get("offline_ai_sub"), style: const TextStyle(fontSize: 12)),
                  value: isOnline,
                  activeColor: const Color(0xFF4F46E5),
                  onChanged: (val) => StorageService.setOnlineMode(val),
                ),
                const Divider(height: 1),
                ListTile(
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

              // --- NOTIFICATIONS ---
              _buildSectionHeader(AppStrings.get("notifications"), textColor),
              _buildSettingGroup([
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFFF59E0B)),
                  title: Text(AppStrings.get("study_reminders"), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(AppStrings.get("reminders_sub"), style: const TextStyle(fontSize: 12)),
                  value: box.get("remindersEnabled", defaultValue: true),
                  onChanged: (val) => box.put("remindersEnabled", val),
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
                  onTap: () {
                    StorageService.logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()), (r) => false);
                  },
                ),
              ], cardColor),

              // --- HELP & SUPPORT ---
              _buildSectionHeader(AppStrings.get("help_support"), textColor),
              _buildSettingGroup([
                ListTile(
                  title: Text(AppStrings.get("send_feedback")),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                  onTap: () {}, // Link to email or form
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(AppStrings.get("privacy_policy")),
                  onTap: () {},
                ),
              ], cardColor),

              const SizedBox(height: 40),
              Center(child: Text("v1.0.0", style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 12))),
              const SizedBox(height: 20),
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
          TextButton(onPressed: () {
            Hive.box('userBox').clear();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()), (r) => false);
          }, child: const Text("Reset App", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}