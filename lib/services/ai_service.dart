import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'storage_service.dart';
import 'statistical_nlp_service.dart';

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);
  @override
  String toString() => message;
}

class AIService {
  // --- CLOUD CONFIGURATION ---
  static String get _apiKey => dotenv.env['GROQ_API_KEY']?.trim() ?? '';
  static const String _endpoint = "https://api.groq.com/openai/v1/chat/completions";
  static const String _model = "llama-3.3-70b-versatile";

  // --- OFFLINE STATE CACHE ---
  static ProcessedDocument? _activeDocument;
  static int? _lastTextHash;

  /// Helper to ensure the offline document is parsed only once per text upload.
  static void _ensureDocumentProcessed(String text) {
    if (text.trim().isEmpty) return;
    
    int currentHash = text.hashCode;
    if (_activeDocument == null || _lastTextHash != currentHash) {
      _activeDocument = StatisticalNLPService.process(text);
      _lastTextHash = currentHash;
    }
  }

  // --- CLOUD HELPER METHODS ---
  static Future<String> _askCloudAI(String prompt) async {
    return _sendToGroq([{"role": "user", "content": prompt}]);
  }

  static Future<String> _sendToGroq(List<Map<String, String>> messages) async {
    if (_apiKey.isEmpty || _apiKey.contains("YOUR_API_KEY")) {
      throw AIServiceException("API Key is empty! Make sure .env is securely loaded.");
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey"
        },
        body: jsonEncode({
          "model": _model,
          "messages": messages,
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        throw AIServiceException("API Error (${response.statusCode}): ${response.body}");
      }
    } on AIServiceException {
      rethrow; 
    } catch (e) {
      throw AIServiceException("Network error: $e");
    }
  }

  // --- CORE FEATURES ROUTER ---

  static Future<String> summarize(String text) async {
    if (text.trim().isEmpty) return "Please provide some text to summarize.";

    if (StorageService.isOnlineMode()) {
      return _askCloudAI("Summarize the following study material clearly using bullet points.\n\n$text");
    } else {
      _ensureDocumentProcessed(text);
      return _activeDocument?.generateSummary(maxSentences: 7) ?? "Processing failed.";
    }
  }

  static Future<String> generateFlashcards(String text) async {
    if (text.trim().isEmpty) return "Please provide some text to generate flashcards.";

    if (StorageService.isOnlineMode()) {
      return _askCloudAI("Create flashcards from this text.\nFormat strictly:\nQ: question\nA: answer\n\nText:\n$text");
    } else {
      _ensureDocumentProcessed(text);
      return _activeDocument?.generateFlashcards(limit: 10) ?? "Processing failed.";
    }
  }

  static Future<String> generateQuiz(String text) async {
    if (text.trim().isEmpty) return "Please provide some text to build a quiz.";

    if (StorageService.isOnlineMode()) {
      return _askCloudAI("Generate a multiple choice quiz.\nFormat strictly:\nQuestion?\nA) option\nB) option\nC) option\nD) option\nAnswer: A\n\nText:\n$text");
    } else {
      _ensureDocumentProcessed(text);
      return _activeDocument?.generateQuiz(limit: 5) ?? "Processing failed.";
    }
  }

  static Future<String> getConceptMap(String text) async {
    if (text.trim().isEmpty) return "Please provide some text.";

    if (StorageService.isOnlineMode()) {
      return _askCloudAI("Identify the 3 main topics in this text and provide the core concept of each in one sentence.\n\nText:\n$text");
    } else {
      _ensureDocumentProcessed(text);
      return _activeDocument?.extractTopics(k: 3) ?? "Processing failed.";
    }
  }

  static Future<String> chat(List<Map<String, String>> conversationHistory, {String? currentDocumentText}) async {
    if (StorageService.isOnlineMode()) {
      // Format chat for Cloud AI
      List<Map<String, String>> formattedHistory = conversationHistory.map((msg) {
        return {
          "role": msg["role"] == "ai" ? "assistant" : "user",
          "content": msg["text"]!
        };
      }).toList();

      formattedHistory.insert(0, {
        "role": "system", 
        "content": "You are StudyMate, a helpful, encouraging AI study assistant."
      });

      return _sendToGroq(formattedHistory);
    } else {
      // Answer locally via Offline TF-IDF Search
      if (currentDocumentText != null && currentDocumentText.isNotEmpty) {
        _ensureDocumentProcessed(currentDocumentText);
      }
      
      if (_activeDocument == null) {
        return "Please upload or open a document first so I have context to answer your questions offline.";
      }

      String userQuestion = conversationHistory.last["text"]!;
      return _activeDocument!.askQuestion(userQuestion);
    }
  }
}