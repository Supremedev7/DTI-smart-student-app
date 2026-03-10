import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {

  static const String apiKey = "";

  static const String endpoint =
      "https://api.groq.com/openai/v1/chat/completions";

  static const String model = "llama-3.3-70b-versatile";

  static Future<String> askAI(String prompt) async {

    final response = await http.post(
      Uri.parse(endpoint),

      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey"
      },

      body: jsonEncode({

        "model": model,

        "messages": [
          {
            "role": "user",
            "content": prompt
          }
        ],

        "temperature": 0.7
      }),
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      return data["choices"][0]["message"]["content"];

    } else {

      throw Exception("Groq API Error: ${response.body}");

    }
  }

  /// Summary
  static Future<String> summarize(String text) async {

    return askAI("""
Summarize the following study material clearly using bullet points.

$text
""");
  }

  /// Flashcards
  static Future<String> generateFlashcards(String text) async {

    return askAI("""
Create flashcards from this text.

Format strictly:

Q: question
A: answer

Text:
$text
""");
  }

  /// Quiz
  static Future<String> generateQuiz(String text) async {

    return askAI("""
Generate a multiple choice quiz.

Format strictly:

Question?
A) option
B) option
C) option
D) option
Answer: A

Text:
$text
""");
  }
}
