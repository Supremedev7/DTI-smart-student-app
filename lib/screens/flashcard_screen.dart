import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart'; 
import '../widgets/flashcard_widget.dart';
import '../utils/app_strings.dart';

class FlashcardScreen extends StatefulWidget {
  final String? initialText;
  final List<Map<String, dynamic>>? savedCards; 
  
  const FlashcardScreen({super.key, this.initialText, this.savedCards});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, String>> cards = [];
  bool loading = false;
  String loadingStatus = "";
  
  // --- STATE TRACKING ---
  int cardsRemaining = 0;
  int totalCards = 0;
  
  bool deckCompleted = false;
  bool xpAwarded = false; 
  bool isTruncated = false; 

  @override
  void initState() {
    super.initState();
    if (widget.savedCards != null && widget.savedCards!.isNotEmpty) {
      _loadSavedDeck();
      return; 
    }

    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      controller.text = widget.initialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generateFlashcards();
      });
    }
  }

  void _loadSavedDeck() {
    cards = widget.savedCards!.map((e) => {"q": e["q"].toString(), "a": e["a"].toString()}).toList();
    setState(() {
      cardsRemaining = cards.length;
      totalCards = cards.length;
      deckCompleted = false;
      xpAwarded = true; // No new XP for replaying saved library decks
    });
  }

  void _reviewAgain() {
    setState(() {
      cardsRemaining = totalCards;
      deckCompleted = false;
    });
  }

  @override
  void dispose() {
    TTSService.stop();
    controller.dispose();
    super.dispose();
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

      // Extract page-by-page to prevent RAM overload (Out of Memory Crash)
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
      if (extractedText.trim().isEmpty) throw Exception("No text found in this PDF.");

      controller.text = extractedText;
      await generateFlashcards(isFromPdf: true);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Future<void> generateFlashcards({bool isFromPdf = false}) async {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Content is too short to generate flashcards. Provide more text.")));
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
      loadingStatus = AppStrings.get("ai_building_deck"); 
      FocusScope.of(context).unfocus(); 
      cards = []; 
      deckCompleted = false;
      xpAwarded = false; // Reset XP flag for a brand new deck
    });

    try {
      String result = await AIService.generateFlashcards(textToProcess);
      List<Map<String, String>> parsed = [];
      List<String> lines = result.split("\n");
      
      String q = "", a = "";
      for (var line in lines) {
        if (line.startsWith("Q:")) q = line.replaceFirst("Q:", "").trim();
        if (line.startsWith("A:")) {
          a = line.replaceFirst("A:", "").trim();
          parsed.add({"q": q, "a": a});
        }
      }

      StorageService.saveToLibrary("flashcard", "Deck - ${DateTime.now().toString().split(' ')[0]}", parsed);

      setState(() {
        cards = parsed;
        cardsRemaining = parsed.length;
        totalCards = parsed.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Generation Error: ${e.toString()}")));
    } finally {
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  // --- DECK COMPLETED SCREEN ---
  Widget _buildCompletionScreen(Color textColor) {
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          Text("Deck Completed!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Text("You reviewed all $totalCards cards.", style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          
          const SizedBox(height: 32),
          
          // --- XP EARNED NOTIFICATION ---
          if (xpAwarded && widget.savedCards == null) 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text("+20 XP Earned!", style: TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _reviewAgain,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Review Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
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

  Widget _buildCardArea(Color textColor) {
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF4F46E5)),
          const SizedBox(height: 20),
          Text(loadingStatus, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      );
    }

    if (cards.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(AppStrings.get("empty_deck"), style: TextStyle(color: textColor, fontSize: 18)),
        ],
      );
    }

    if (deckCompleted) {
      return _buildCompletionScreen(textColor);
    }

    return CardSwiper(
      cardsCount: cards.length,
      numberOfCardsDisplayed: cards.length > 3 ? 3 : cards.length,
      isLoop: false,
      onSwipe: (previousIndex, currentIndex, direction) {
        TTSService.stop(); 
        setState(() {
          cardsRemaining--; 
          if (cardsRemaining == 0) {
             deckCompleted = true;
             
             if (!xpAwarded) {
               StorageService.addXP(20);
               // --- THE STREAK UPDATE FIX ---
               StorageService.updateStreak(); // Tells the app the user studied today!
               StorageService.addRecentActivity("Studied Deck", "Completed review (+20 XP)", "flashcard");
               xpAwarded = true;
             }
          }
        });
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return FlashcardWidget(
          // UNIQUE KEY FIXES THE FLIP RETENTION BUG
          key: ValueKey("flashcard_${index}_${cards[index]["q"]}"),
          question: cards[index]["q"]!, 
          answer: cards[index]["a"]!
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
            title: Text(AppStrings.get("study_deck"), style: TextStyle(fontWeight: FontWeight.bold, color: titleColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: titleColor),
            leading: (widget.initialText != null || widget.savedCards != null) 
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
                          hintText: AppStrings.get("paste_deck"),
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
                              onPressed: loading ? null : () => generateFlashcards(), 
                              icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome), 
                              label: Text(loading ? AppStrings.get("working") : AppStrings.get("generate_cards")), 
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14), 
                                backgroundColor: const Color(0xFF4F46E5), 
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
                                  "Note: We took the first portion of the content to build the deck due to high volume.",
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
                  child: _buildCardArea(textColor),
                ))),
                
                // Dynamic Footer
                if (!loading && cards.isNotEmpty && !deckCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 30.0), 
                    child: Text("$cardsRemaining ${AppStrings.get("cards_remaining")}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600))
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}