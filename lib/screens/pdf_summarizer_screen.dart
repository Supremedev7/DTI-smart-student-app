import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

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
  String currentFileName = "Custom Notes"; // Track the file name

  Future<void> pickAndExtractPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf"],
    );

    if (result == null) return;

    setState(() {
      loading = true;
      loadingStatus = "Reading PDF...";
      FocusScope.of(context).unfocus();
    });

    try {
      final path = result.files.single.path!;
      currentFileName = result.files.single.name; // Save the file name
      
      final PdfDocument document = PdfDocument(inputBytes: File(path).readAsBytesSync());
      
      String extractedText = PdfTextExtractor(document)
          .extractText(startPageIndex: 0, endPageIndex: document.pages.count > 3 ? 2 : document.pages.count - 1);
      
      document.dispose();

      if (extractedText.trim().isEmpty) {
        throw Exception("No readable text found in this PDF.");
      }

      controller.text = extractedText;
      await summarizeText(isFromPdf: true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF Error: ${e.toString()}")));
      setState(() {
        loading = false;
        loadingStatus = "";
      });
    }
  }

  Future<void> summarizeText({bool isFromPdf = false}) async {
    if (controller.text.isEmpty && !isFromPdf) return;

    setState(() {
      loading = true;
      loadingStatus = "Generating summary...";
      FocusScope.of(context).unfocus();
    });

    try {
      String result = await AIService.summarize(controller.text);
      
      // --- LOG ACTIVITY & GIVE XP ---
      StorageService.addXP(30);
      if (isFromPdf) {
         StorageService.incrementPdfs();
         StorageService.addRecentActivity("Summarized PDF", currentFileName, "summary");
      } else {
         StorageService.addRecentActivity("Summarized Notes", "Custom Text", "summary");
      }

      setState(() {
        summary = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        loading = false;
        loadingStatus = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFFF8FAFC);
    final primaryColor = const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Summarizer", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                decoration: InputDecoration(
                  hintText: "Paste your study notes or upload a PDF to get a quick summary...",
                  filled: true,
                  fillColor: Colors.white,
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
                      label: const Text("PDF"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : () => summarizeText(),
                      icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                      label: Text(loading ? loadingStatus : "Summarize"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              if (summary.isNotEmpty && !loading) ...[
                const Text("Key Takeaways", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: SelectableText(summary, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.6)),
                ),
                const SizedBox(height: 24),
                const Text("Next Steps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardScreen(initialText: controller.text)));
                        },
                        icon: const Icon(Icons.style_rounded),
                        label: const Text("Flashcards"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(initialText: controller.text)));
                        },
                        icon: const Icon(Icons.quiz_rounded),
                        label: const Text("Take Quiz"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              if (summary.isEmpty && !loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.document_scanner_rounded, size: 60, color: primaryColor.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 20),
                        Text("Ready to summarize", style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w500)),
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
}