import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  // We expose this so our UI can listen to start/stop events
  static final FlutterTts ttsEngine = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    
    await ttsEngine.setLanguage("en-US");
    await ttsEngine.setSpeechRate(0.5); // Conversational speed
    await ttsEngine.setVolume(1.0);
    await ttsEngine.setPitch(1.0);
    
    _isInitialized = true;
  }

  static Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    await ttsEngine.stop(); // Stop anything currently playing
    if (text.isNotEmpty) {
      await ttsEngine.speak(text);
    }
  }

  static Future<void> stop() async {
    await ttsEngine.stop();
  }
}