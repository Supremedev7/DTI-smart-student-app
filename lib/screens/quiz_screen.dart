import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/quiz_card.dart';
import '../utils/app_strings.dart';

class QuizScreen extends StatefulWidget {
  final String? initialText;
  final List<Map<String, dynamic>>? savedQuiz;

  const QuizScreen({super.key, this.initialText, this.savedQuiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, dynamic>> questions = [];
  bool loading = false;
  String loadingStatus = "";
  
  // --- STATE TRACKING ---
  int questionsRemaining = 0;
  int correctAnswers = 0;
  int totalQuestions = 0;
  
  bool quizCompleted = false;
  bool xpAwarded = false; 
  bool isTruncated = false; 

  @override
  void initState() {
    super.initState();
    
    if (widget.savedQuiz != null && widget.savedQuiz!.isNotEmpty) {
      _loadSavedQuiz();
      return;
    }

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      controller.text = widget.initialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generateQuiz();
      });
    }
  }

  void _loadSavedQuiz() {
    questions = widget.savedQuiz!.map((e) => {
      "question": e["question"].toString(),
      "options": List<String>.from(e["options"]),
      "answer": e["answer"] as int
    }).toList();
    
    setState(() {
      questionsRemaining = questions.length;
      totalQuestions = questions.length;
      correctAnswers = 0;
      quizCompleted = false;
      xpAwarded = true; // No new XP for replaying saved library quizzes
    });
  }

  void _retryQuiz() {
    setState(() {
      questionsRemaining = totalQuestions;
      correctAnswers = 0;
      quizCompleted = false;
      // Note: xpAwarded remains true so they don't farm XP by retrying
    });
  }

  // --- THE CRASH FIX: Secure Page-by-Page Extraction ---
  Future<void> pickAndExtractPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);
    if (result == null) return;

    setState(() { 
      loading = true; 
      loadingStatus = "Checking PDF..."; 
      FocusScope.of(context).unfocus(); 
      isTruncated = false;
    });

    try {
      final path = result.files.single.path!;
      final file = File(path);
      
      // REQUIREMENT 1: 5MB File Size Limit
      if (file.lengthSync() > 5 * 1024 * 1024) {
        throw Exception("PDF is too big. Maximum allowed size is 5MB.");
      }

      setState(() => loadingStatus = "Reading PDF securely...");

      // Extract page-by-page to prevent RAM overload
      final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      StringBuffer textBuffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        textBuffer.write(extractor.extractText(startPageIndex: i, endPageIndex: i));
        textBuffer.write(" ");

        await Future.delayed(const Duration(milliseconds: 10));

        // Stop reading the PDF early to save memory
        if (textBuffer.length > 6000) break;
      }

      document.dispose();
      String extractedText = textBuffer.toString();

      // REQUIREMENT 2: Empty Check
      if (extractedText.trim().isEmpty) {
        throw Exception("PDF is empty or invalid.");
      }

      controller.text = extractedText;
      await generateQuiz(isFromPdf: true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Future<void> generateQuiz({bool isFromPdf = false}) async {
    String textToProcess = controller.text.trim();

    // REQUIREMENT 3: Empty Submission Check
    if (textToProcess.isEmpty) {
      if (!isFromPdf) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload a PDF or paste text and try again.")));
      }
      return;
    }

    // REQUIREMENT 4: Too Short Check
    if (textToProcess.length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Content is too short to generate a quiz. Provide more text.")));
      return;
    }

    bool wasTruncated = false;

    // REQUIREMENT 5: Dynamic Truncation Limits based on AI mode
    int limit = StorageService.isOnlineMode() ? 25000 : 5000;
    if (textToProcess.length > limit) {
      textToProcess = textToProcess.substring(0, limit);
      wasTruncated = true;
    }

    setState(() { 
      isTruncated = wasTruncated;
      loading = true; 
      loadingStatus = AppStrings.get("ai_writing_quiz");
      FocusScope.of(context).unfocus(); 
      
      questions = []; 
      correctAnswers = 0;
      quizCompleted = false;
      xpAwarded = false; // Reset XP flag for a brand new quiz
    });

    try {
      String result = await AIService.generateQuiz(textToProcess);
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
      
      StorageService.saveToLibrary("quiz", "Quiz - ${DateTime.now().toString().split(' ')[0]}", parsed);

      setState(() {
        questions = parsed;
        questionsRemaining = parsed.length;
        totalQuestions = parsed.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to generate quiz: $e")));
    } finally {
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  // --- GAME-LIKE SCORE SCREEN ---
  Widget _buildScoreScreen(Color textColor) {
    double percentage = correctAnswers / totalQuestions;
    Color scoreColor = percentage >= 0.8 ? const Color(0xFF10B981) : (percentage >= 0.5 ? const Color(0xFFF59E0B) : Colors.red);
    String title = percentage >= 0.8 ? "Outstanding!" : (percentage >= 0.5 ? "Good Job!" : "Keep Practicing!");
    
    int xpEarned = correctAnswers * 10; 

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 32),
          
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 12,
                  backgroundColor: scoreColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$correctAnswers / $totalQuestions", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: scoreColor)),
                  Text("Score", style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          if (xpEarned > 0 && xpAwarded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text("+$xpEarned XP Earned!", style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retryQuiz,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuizArea(Color textColor) {
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFEC4899)),
          const SizedBox(height: 20),
          Text(loadingStatus, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );
    }

    if (questions.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(AppStrings.get("empty_quiz"), style: TextStyle(color: textColor, fontSize: 18)),
        ],
      );
    }

    if (quizCompleted) {
      return _buildScoreScreen(textColor);
    }

    return CardSwiper(
      cardsCount: questions.length,
      numberOfCardsDisplayed: questions.length > 3 ? 3 : questions.length,
      isLoop: false,
      onSwipe: (previousIndex, currentIndex, direction) {
        setState(() { 
          questionsRemaining--; 
          if(questionsRemaining == 0) {
            quizCompleted = true;
            
            if (!xpAwarded) {
              int xp = correctAnswers * 10;
              if (xp > 0) StorageService.addXP(xp);
              // --- THE STREAK UPDATE FIX ---
              StorageService.updateStreak(); // Tells the app the user studied today!
              StorageService.incrementQuizzes();
              StorageService.addRecentActivity("Completed Quiz", "Scored $correctAnswers/$totalQuestions (+${xp}XP)", "quiz");
              xpAwarded = true; 
            }
          }
        });
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        final q = questions[index];
        return QuizCard(
          // UNIQUE KEY FIXES THE RETAINED ANSWER BUG
          key: ValueKey("quiz_card_${index}_${q['question']}"), 
          question: q["question"], 
          options: List<String>.from(q["options"]), 
          correctIndex: q["answer"],
          onAnswered: (bool isCorrect) {
            if (isCorrect) {
              setState(() => correctAnswers++);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColor = isDark ? Colors.grey.shade300 : const Color(0xFF334155);
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return ValueListenableBuilder(
      valueListenable: Hive.box('userBox').listenable(),
      builder: (context, box, child) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(AppStrings.get("study_quiz"), style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: titleColor),
            leading: (widget.initialText != null || widget.savedQuiz != null) 
                ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)) 
                : null,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 20),
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        maxLines: 3,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: AppStrings.get("paste_quiz"),
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          filled: true, 
                          fillColor: cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 1, 
                            child: OutlinedButton.icon(
                              onPressed: loading ? null : pickAndExtractPDF, 
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444)), 
                              label: Text(AppStrings.get("pdf_btn"), style: TextStyle(color: titleColor)), 
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14), 
                                backgroundColor: cardColor, 
                                side: BorderSide(color: borderColor), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              )
                            )
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2, 
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : () => generateQuiz(), 
                              icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome), 
                              label: Text(loading ? AppStrings.get("working") : AppStrings.get("generate_quiz")), 
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14), 
                                backgroundColor: const Color(0xFFEC4899), 
                                foregroundColor: Colors.white, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              )
                            )
                          ),
                        ],
                      ),
                      
                      // TRUNCATION WARNING UI (Updated text for dynamic limit)
                      if (isTruncated && !loading)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Note: We took the first portion of the content to generate the quiz due to high volume.",
                                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Swiper Area
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildQuizArea(textColor),
                ))),
                
                // Dynamic Footer
                if (!loading && questions.isNotEmpty && !quizCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 30.0), 
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text("Score: $correctAnswers / $totalQuestions", 
                            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text("$questionsRemaining ${AppStrings.get("questions_remaining")}", 
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)
                        ),
                      ],
                    )
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}