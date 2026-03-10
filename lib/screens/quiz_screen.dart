import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/quiz_card.dart';

class QuizScreen extends StatefulWidget {
  final String? initialText;
  const QuizScreen({super.key, this.initialText});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> questions = [];
  bool loading = false;
  String loadingStatus = "";
  int questionsRemaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      controller.text = widget.initialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generateQuiz();
      });
    }
  }

  Future<void> pickAndExtractPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);
    if (result == null) return;

    setState(() { loading = true; loadingStatus = "Extracting text from PDF..."; FocusScope.of(context).unfocus(); });

    try {
      final path = result.files.single.path!;
      final PdfDocument document = PdfDocument(inputBytes: File(path).readAsBytesSync());
      String extractedText = PdfTextExtractor(document).extractText(startPageIndex: 0, endPageIndex: document.pages.count > 3 ? 2 : document.pages.count - 1);
      document.dispose();

      if (extractedText.trim().isEmpty) throw Exception("No text found in PDF.");

      controller.text = extractedText;
      await generateQuiz(isFromPdf: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: ${e.toString()}")));
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Future<void> generateQuiz({bool isFromPdf = false}) async {
    if (controller.text.isEmpty && !isFromPdf) return;

    setState(() { loading = true; loadingStatus = "AI is writing your quiz..."; FocusScope.of(context).unfocus(); questions = []; });

    try {
      String result = await AIService.generateQuiz(controller.text);
      List<Map<String, dynamic>> parsed = [];
      List<String> lines = result.split("\n");

      String question = "";
      List<String> options = [];
      int answer = 0;

      for (var line in lines) {
        if (line.contains("?")) question = line.trim();
        if (line.startsWith("A)")) options.add(line.replaceFirst("A)", "").trim());
        if (line.startsWith("B)")) options.add(line.replaceFirst("B)", "").trim());
        if (line.startsWith("C)")) options.add(line.replaceFirst("C)", "").trim());
        if (line.startsWith("D)")) options.add(line.replaceFirst("D)", "").trim());
        
        if (line.startsWith("Answer")) {
          if (line.contains("A")) answer = 0;
          if (line.contains("B")) answer = 1;
          if (line.contains("C")) answer = 2;
          if (line.contains("D")) answer = 3;

          parsed.add({"question": question, "options": List<String>.from(options), "answer": answer});
          options.clear();
        }
      }
      
      // Track Generation
      StorageService.addRecentActivity("Generated Quiz", "${parsed.length} Questions", "quiz");

      setState(() {
        questions = parsed;
        questionsRemaining = parsed.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to generate quiz: $e")));
    } finally {
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Widget _buildQuizArea() {
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFEC4899)),
          const SizedBox(height: 20),
          Text(loadingStatus, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );
    }

    if (questions.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No quiz generated yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 18)),
        ],
      );
    }

    return CardSwiper(
      cardsCount: questions.length,
      numberOfCardsDisplayed: questions.length > 3 ? 3 : questions.length,
      isLoop: false,
      onSwipe: (previousIndex, currentIndex, direction) {
        setState(() { 
          questionsRemaining--; 
          if(questionsRemaining == 0) {
            // Reward XP and increment stats when completed
            StorageService.addXP(50);
            StorageService.incrementQuizzes();
            StorageService.addRecentActivity("Completed Quiz", "Earned 50 XP", "quiz");
          }
        });
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        final q = questions[index];
        return QuizCard(question: q["question"], options: List<String>.from(q["options"]), correctIndex: q["answer"]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Study Quiz", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.initialText != null ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)) : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Paste notes or upload a PDF to generate a quiz...",
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 1, child: OutlinedButton.icon(onPressed: loading ? null : pickAndExtractPDF, icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)), label: const Text("PDF"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton.icon(onPressed: loading ? null : () => generateQuiz(), icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome), label: Text(loading ? "Working..." : "Generate Quiz"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(child: Center(child: _buildQuizArea())),
            
            if (!loading && questions.isNotEmpty && questionsRemaining > 0)
              Padding(padding: const EdgeInsets.only(top: 20.0), child: Text("$questionsRemaining questions remaining", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
            if (!loading && questions.isNotEmpty && questionsRemaining == 0)
              const Padding(padding: EdgeInsets.only(top: 20.0), child: Text("Quiz Completed! 🎉 +50 XP", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      ),
    );
  }
}