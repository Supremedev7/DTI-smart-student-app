import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../utils/app_strings.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String modeValue,
    required String currentMode,
    required Color cardColor,
    required Color textColor,
  }) {
    final bool isSelected = currentMode == modeValue;

    return GestureDetector(
      onTap: () {
        StorageService.setThemeMode(modeValue);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade500),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF4F46E5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('userBox').listenable(),
      builder: (context, box, child) {
        final currentTheme = StorageService.getThemeMode();
        final bgColor = Theme.of(context).scaffoldBackgroundColor;
        final cardColor = Theme.of(context).cardColor;
        final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              AppStrings.get("theme"),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose how Smart Student looks to you.",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildThemeOption(
                  context: context,
                  title: AppStrings.get("system_default"),
                  icon: Icons.settings_brightness_rounded,
                  modeValue: 'system',
                  currentMode: currentTheme,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                _buildThemeOption(
                  context: context,
                  title: AppStrings.get("light_mode"),
                  icon: Icons.light_mode_rounded,
                  modeValue: 'light',
                  currentMode: currentTheme,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
                _buildThemeOption(
                  context: context,
                  title: AppStrings.get("dark_mode"),
                  icon: Icons.dark_mode_rounded,
                  modeValue: 'dark',
                  currentMode: currentTheme,
                  cardColor: cardColor,
                  textColor: textColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}