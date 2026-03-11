import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/flashcard_widget.dart';
import '../utils/app_strings.dart';

class FlashcardScreen extends StatefulWidget {
  final String? initialText;
  const FlashcardScreen({super.key, this.initialText});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final TextEditingController controller = TextEditingController();
  List<Map<String, String>> cards = [];
  bool loading = false;
  String loadingStatus = "";
  int cardsRemaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      controller.text = widget.initialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generateFlashcards();
      });
    }
  }

  Future<void> pickAndExtractPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);
    if (result == null) return;

    setState(() { 
      loading = true; 
      loadingStatus = "Extracting text from PDF..."; 
      FocusScope.of(context).unfocus(); 
    });

    try {
      final path = result.files.single.path!;
      final PdfDocument document = PdfDocument(inputBytes: File(path).readAsBytesSync());
      String extractedText = PdfTextExtractor(document).extractText(startPageIndex: 0, endPageIndex: document.pages.count > 3 ? 2 : document.pages.count - 1);
      document.dispose();

      if (extractedText.trim().isEmpty) throw Exception("No text found in this PDF.");

      controller.text = extractedText;
      await generateFlashcards(isFromPdf: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: ${e.toString()}")));
      setState(() { loading = false; loadingStatus = ""; });
    }
  }

  Future<void> generateFlashcards({bool isFromPdf = false}) async {
    if (controller.text.isEmpty && !isFromPdf) return;

    setState(() { 
      loading = true; 
      loadingStatus = AppStrings.get("ai_building_deck"); 
      FocusScope.of(context).unfocus(); 
      cards = []; 
    });

    try {
      String result = await AIService.generateFlashcards(controller.text);
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

      StorageService.addRecentActivity("Generated Deck", "${parsed.length} Flashcards", "flashcard");

      setState(() {
        cards = parsed;
        cardsRemaining = parsed.length;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Generation Error: ${e.toString()}")));
    } finally {
      setState(() { loading = false; loadingStatus = ""; });
    }
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

    return CardSwiper(
      cardsCount: cards.length,
      numberOfCardsDisplayed: cards.length > 3 ? 3 : cards.length,
      isLoop: false,
      onSwipe: (previousIndex, currentIndex, direction) {
        setState(() {
          cardsRemaining--; 
          if (cardsRemaining == 0) {
             StorageService.addXP(20);
             StorageService.addRecentActivity("Studied Deck", "Completed review", "flashcard");
          }
        });
        return true;
      },
      cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
        return FlashcardWidget(question: cards[index]["q"]!, answer: cards[index]["a"]!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- THEME DYNAMICS ---
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
            leading: widget.initialText != null ? IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)) : null,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(height: 30),
                Expanded(child: Center(child: _buildCardArea(textColor))),
                
                if (!loading && cards.isNotEmpty && cardsRemaining > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0), 
                    child: Text("$cardsRemaining ${AppStrings.get("cards_remaining")}", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600))
                  ),
                if (!loading && cards.isNotEmpty && cardsRemaining == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0), 
                    child: Text(AppStrings.get("deck_completed"), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16))
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}