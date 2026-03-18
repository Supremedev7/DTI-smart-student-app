import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../utils/app_strings.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class PdfSummarizerScreen extends StatefulWidget {
  const PdfSummarizerScreen({super.key});

  @override
  State<PdfSummarizerScreen> createState() => _PdfSummarizerScreenState();
}

class _PdfSummarizerScreenState extends State<PdfSummarizerScreen> {
  final TextEditingController controller = TextEditingController();
  String summary = "";
  bool loading = false;
  String loadingStatus = "";
  
  // TTS & Truncation States
  bool isSpeaking = false;
  bool isPaused = false;
  bool isTruncated = false; // Tracks if the >5k character limit was hit

  bool get _isOcrSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void initState() {
    super.initState();
    
    TTSService.init();
    
    TTSService.ttsEngine.setStartHandler(() {
      if (mounted) setState(() { isSpeaking = true; isPaused = false; });
    });
    
    TTSService.ttsEngine.setCompletionHandler(() {
      if (mounted) setState(() { isSpeaking = false; isPaused = false; });
    });
    
    TTSService.ttsEngine.setCancelHandler(() {
      if (mounted) setState(() { isSpeaking = false; isPaused = false; });
    });

    TTSService.ttsEngine.setPauseHandler(() {
      if (mounted) setState(() { isSpeaking = true; isPaused = true; });
    });

    TTSService.ttsEngine.setContinueHandler(() {
      if (mounted) setState(() { isSpeaking = true; isPaused = false; });
    });
  }

  @override
  void dispose() {
    TTSService.stop(); 
    controller.dispose();
    super.dispose();
  }

  void _toggleSpeech() {
    if (isSpeaking && !isPaused) {
      TTSService.ttsEngine.pause();
    } else {
      TTSService.speak(summary); 
    }
  }

  // --- Secure Page-by-Page Extraction ---
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

      // Extract page-by-page to prevent RAM overload (Out of Memory Crash)
      final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      StringBuffer textBuffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        textBuffer.write(extractor.extractText(startPageIndex: i, endPageIndex: i));
        textBuffer.write(" ");

        // Yield to the event loop so the UI spinner keeps animating
        await Future.delayed(const Duration(milliseconds: 10));

        // Stop reading the PDF early to save memory
        if (textBuffer.length > 6000) break;
      }

      document.dispose();
      String extractedText = textBuffer.toString();

      // REQUIREMENT 2: Empty PDF Check
      if (extractedText.trim().isEmpty) {
        throw Exception("PDF is empty or invalid. If this is a scanned PDF, please use the 'Scan' button instead.");
      }
      
      controller.text = extractedText;
      await summarizeText(isAutoProcess: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Future<void> pickAndExtractImage() async {
    if (!_isOcrSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OCR Scanning is only supported on Android/iOS devices.")),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() {
      loading = true;
      loadingStatus = "Scanning handwriting...";
      FocusScope.of(context).unfocus();
      isTruncated = false;
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text;
      
      textRecognizer.close();

      if (extractedText.trim().isEmpty) {
        throw Exception("Could not read any text from this image.");
      }

      controller.text = extractedText;
      await summarizeText(isAutoProcess: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Future<void> summarizeText({bool isAutoProcess = false}) async {
    String textToProcess = controller.text.trim();

    // REQUIREMENT 3: Empty Submission Check
    if (textToProcess.isEmpty) {
      if (!isAutoProcess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload a PDF or paste text and try again.")));
      }
      return;
    }

    // REQUIREMENT 4: Too Short Check
    if (textToProcess.length < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Content is too short to summarize. Please provide more text.")));
      return;
    }

    TTSService.stop(); 
    bool wasTruncated = false;

    // REQUIREMENT 5: Dynamic Truncation based on Online/Offline mode
    int limit = StorageService.isOnlineMode() ? 25000 : 5000;
    if (textToProcess.length > limit) {
      textToProcess = textToProcess.substring(0, limit);
      wasTruncated = true;
    }

    setState(() {
      isTruncated = wasTruncated;
      loading = true;
      loadingStatus = AppStrings.get("generating");
      FocusScope.of(context).unfocus();
    });

    try {
      // Passes the text into the unified Offline/Online AI router
      String result = await AIService.summarize(textToProcess); 
      String targetLang = StorageService.getLanguage();
      
      if (targetLang != "English") {
        setState(() => loadingStatus = "Translating...");
        result = await TranslationService.translate(result, targetLang);
      }
      
      // --- THE STREAK UPDATE FIX ---
      StorageService.addXP(30);
      StorageService.updateStreak(); // Tells the app the user studied today!
      StorageService.addRecentActivity("Generated Summary", "Earned 30 XP", "summary");
      
      StorageService.saveToLibrary(
        "summary", 
        "Summary - ${DateTime.now().toString().split(' ')[0]}", 
        result
      );
      
      setState(() => summary = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() { loading = false; loadingStatus = ""; });
    }
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
            title: Text(AppStrings.get("summarizer"), style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: titleColor),
          ),
          
          floatingActionButton: (summary.isNotEmpty && !loading) 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSpeaking || isPaused)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FloatingActionButton(
                        heroTag: "btn_tts_stop",
                        mini: true, 
                        onPressed: () => TTSService.stop(),
                        backgroundColor: Colors.red,
                        tooltip: "Stop Audio",
                        child: const Icon(Icons.stop_rounded, color: Colors.white),
                      ),
                    ),
                    
                  FloatingActionButton.extended(
                    heroTag: "btn_tts_play_pause",
                    onPressed: _toggleSpeech,
                    backgroundColor: const Color(0xFF4F46E5),
                    icon: Icon(
                      (isSpeaking && !isPaused) ? Icons.pause_rounded : Icons.volume_up_rounded, 
                      color: Colors.white
                    ),
                    label: Text(
                      (isSpeaking && !isPaused) ? "Pause" : (isPaused ? "Resume" : "Listen"), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              )
            : null,
            
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: AppStrings.get("paste_notes"), 
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
                          icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 18),
                          label: Text("PDF", style: TextStyle(color: titleColor)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                            backgroundColor: cardColor,
                            side: BorderSide(color: borderColor)
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: loading ? null : pickAndExtractImage,
                          icon: const Icon(Icons.document_scanner_rounded, color: Color(0xFF3B82F6), size: 18),
                          label: Text("Scan", style: TextStyle(color: titleColor)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                            backgroundColor: cardColor,
                            side: BorderSide(color: borderColor)
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : () => summarizeText(),
                          icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(loading ? "..." : AppStrings.get("summarize_btn")), 
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (summary.isNotEmpty && !loading) ...[
                    Text(AppStrings.get("key_takeaways"), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)), 
                    const SizedBox(height: 12),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor, 
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: borderColor)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(summary, style: TextStyle(fontSize: 15, color: textColor, height: 1.6)),
                          
                          // High Content Warning UI
                          if (isTruncated) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Note: We took the first portion of the content to process due to high volume.",
                                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(AppStrings.get("next_steps"), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)), 
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              TTSService.stop();
                              Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardScreen(initialText: controller.text)));
                            },
                            icon: const Icon(Icons.style_rounded),
                            label: Text(AppStrings.get("flashcards")), 
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              TTSService.stop();
                              Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(initialText: controller.text)));
                            },
                            icon: const Icon(Icons.quiz_rounded),
                            label: Text(AppStrings.get("take_quiz")), 
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 80),
                  ],
                  
                  if (summary.isEmpty && !loading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Column(
                          children: [
                            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.document_scanner_rounded, size: 60, color: const Color(0xFF10B981).withOpacity(0.5))),
                            const SizedBox(height: 20),
                            Text(AppStrings.get("ready_to_summarize"), style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w500)), 
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}