import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/storage_service.dart';
import 'main_navigation.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _navigated = false; // Prevents multiple navigation triggers

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(false);
        _controller.play();
      });

    _controller.addListener(() {
      // Check if video has reached the end
      if (!_navigated && 
          _controller.value.isInitialized && 
          _controller.value.position >= _controller.value.duration) {
        
        _navigated = true;
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    // Determine where to send the user based on their login state
    Widget nextScreen = const OnboardingScreen();
    if (StorageService.isOnboardingComplete() && StorageService.isLoggedIn()) {
      nextScreen = const MainNavigation();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for splash
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // Ensures the video fills the screen
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
    );
  }
}