import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final _modelManager = OnDeviceTranslatorModelManager();

  // Helper to check if ML Kit is supported on the current device
  static bool get _isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // Helper to get the correct Google Language Code
  static String _getCode(String langStr) {
    switch (langStr) {
      case "Hindi": return TranslateLanguage.hindi.bcpCode;
      case "Telugu": return TranslateLanguage.telugu.bcpCode;
      case "Tamil": return TranslateLanguage.tamil.bcpCode;
      default: return "";
    }
  }

  // Used by Settings UI to check if we need to show the Download button
  static Future<bool> isLanguageDownloaded(String langStr) async {
    if (langStr == "English") return true; 
    
    // BYPASS FOR LINUX: Pretend it's downloaded so the UI doesn't crash
    if (!_isSupported) return true; 

    String code = _getCode(langStr);
    if (code.isEmpty) return true;
    
    return await _modelManager.isModelDownloaded(code);
  }

  // Used by Settings UI when the user clicks "Download"
  static Future<bool> downloadLanguage(String langStr) async {
    // BYPASS FOR LINUX: Prevent downloading native models on desktop
    if (!_isSupported) return false; 
    
    String code = _getCode(langStr);
    if (code.isEmpty) return false;
    
    return await _modelManager.downloadModel(code);
  }

  // The actual translator used by the Summarizer/Flashcards
  static Future<String> translate(String text, String targetLangStr) async {
    if (targetLangStr == "English" || text.trim().isEmpty) return text;

    // BYPASS FOR LINUX: Just return the original English text
    if (!_isSupported) return text; 

    TranslateLanguage targetLang;
    switch (targetLangStr) {
      case "Hindi": targetLang = TranslateLanguage.hindi; break;
      case "Telugu": targetLang = TranslateLanguage.telugu; break;
      case "Tamil": targetLang = TranslateLanguage.tamil; break;
      default: return text;
    }

    final bool isDownloaded = await _modelManager.isModelDownloaded(targetLang.bcpCode);
    
    if (!isDownloaded) {
      await _modelManager.downloadModel(targetLang.bcpCode);
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: targetLang,
    );

    final String result = await translator.translateText(text);
    translator.close();
    
    return result;
  }
}