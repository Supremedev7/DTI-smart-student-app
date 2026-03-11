import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'storage_service.dart';
import 'smart_offline_nlp.dart'; // Pointing to your new, highly intelligent offline algorithm!

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);
  @override
  String toString() => message;
}

class AIService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _endpoint = "https://api.groq.com/openai/v1/chat/completions";
  static const String _model = "llama-3.3-70b-versatile";

  static Future<String> _askAI(String prompt) async {
    if (_apiKey.isEmpty) throw AIServiceException("API Key is missing. Check your .env file.");

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey"
        },
        body: jsonEncode({
          "model": _model,
          "messages": [{"role": "user", "content": prompt}],
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        throw AIServiceException("API Error (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      throw AIServiceException("Network error: $e");
    }
  }

  // --- THE UNIFIED HYBRID ROUTER ---

  static Future<String> summarize(String text) async {
    if (StorageService.isOnlineMode()) {
      return _askAI("Summarize the following study material clearly using bullet points.\n\n$text");
    } else {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulates thinking time for UI
      return SmartOfflineNLPService.summarize(text); 
    }
  }

  static Future<String> generateFlashcards(String text) async {
    if (StorageService.isOnlineMode()) {
      return _askAI("Create flashcards from this text.\nFormat strictly:\nQ: question\nA: answer\n\nText:\n$text");
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      return SmartOfflineNLPService.generateFlashcards(text);
    }
  }

  static Future<String> generateQuiz(String text) async {
    if (StorageService.isOnlineMode()) {
      return _askAI("Generate a multiple choice quiz.\nFormat strictly:\nQuestion?\nA) option\nB) option\nC) option\nD) option\nAnswer: A\n\nText:\n$text");
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      return SmartOfflineNLPService.generateQuiz(text);
    }
  }
}