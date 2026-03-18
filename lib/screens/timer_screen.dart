import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const int focusDuration = 25 * 60; // 25 minutes in seconds
  int timeRemaining = focusDuration;
  Timer? timer;
  bool isRunning = false;

  void startTimer() {
    if (timer != null) timer!.cancel();
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() => timeRemaining--);
      } else {
        stopTimer();
        _sessionCompleted();
      }
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      timeRemaining = focusDuration;
    });
  }

  void stopTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void _sessionCompleted() {
    // GAMIFICATION TIE-IN: Reward the user for 25 mins of pure focus!
    StorageService.addXP(50); 
    StorageService.updateStreak();
    StorageService.addRecentActivity("Focus Session", "Completed 25 mins (+50 XP)", "timer");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 60),
            SizedBox(height: 16),
            Text("Session Complete!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Great job staying focused! You've earned 50 XP and kept your study streak alive.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              resetTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Start Another"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardColor = Theme.of(context).cardColor;

    double progress = timeRemaining / focusDuration;

    return ValueListenableBuilder(
      valueListenable: Hive.box('userBox').listenable(),
      builder: (context, box, child) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text("Focus Timer", style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- CIRCULAR TIMER UI ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 16,
                            backgroundColor: cardColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)), // Tomato Red
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatTime(timeRemaining),
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isRunning ? "Focusing..." : (timeRemaining == focusDuration ? "Ready to focus?" : "Paused"),
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // --- CONTROLS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (timeRemaining < focusDuration)
                          Padding(
                            padding: const EdgeInsets.only(right: 20.0),
                            child: IconButton(
                              onPressed: resetTimer,
                              icon: const Icon(Icons.refresh_rounded, size: 32),
                              color: Colors.grey.shade500,
                              tooltip: "Reset",
                            ),
                          ),
                          
                        FloatingActionButton.large(
                          onPressed: isRunning ? pauseTimer : startTimer,
                          backgroundColor: isRunning ? cardColor : const Color(0xFFEF4444),
                          elevation: isRunning ? 2 : 6,
                          child: Icon(
                            isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: isRunning ? const Color(0xFFEF4444) : Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}