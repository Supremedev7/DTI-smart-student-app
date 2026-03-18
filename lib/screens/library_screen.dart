import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text("My Library", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          bottom: TabBar(
            labelColor: const Color(0xFF4F46E5),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF4F46E5),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "Summaries"),
              Tab(text: "Flashcards"),
              Tab(text: "Quizzes"),
            ],
          ),
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box('userBox').listenable(),
          builder: (context, box, child) {
            return TabBarView(
              children: [
                _buildList("summary"),
                _buildList("flashcard"),
                _buildList("quiz"),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildList(String type) {
    List<Map<String, dynamic>> items = StorageService.getLibraryItems(type);
    final cardColor = Theme.of(context).cardColor;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text("No saved items yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        IconData icon = Icons.article;
        Color color = Colors.blue;

        if (type == "summary") {
          icon = Icons.document_scanner_rounded;
          color = const Color(0xFF10B981);
        } else if (type == "flashcard") {
          icon = Icons.style_rounded;
          color = const Color(0xFFF59E0B);
        } else if (type == "quiz") {
          icon = Icons.quiz_rounded;
          color = const Color(0xFFEC4899);
        }

        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2))
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            title: Text(item["title"] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item["date"].toString().split('T')[0], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                StorageService.deleteLibraryItem(type, index);
                setState((){}); // refresh
              },
            ),
            onTap: () => _openItem(type, item),
          ),
        );
      },
    );
  }

  void _openItem(String type, Map<String, dynamic> item) {
    if (type == "flashcard") {
      List<Map<String, dynamic>> savedData = List<Map<String, dynamic>>.from(item["content"]);
      Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardScreen(savedCards: savedData)));
    } else if (type == "quiz") {
      List<Map<String, dynamic>> savedData = List<Map<String, dynamic>>.from(item["content"]);
      Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(savedQuiz: savedData)));
    } else if (type == "summary") {
      _showSummaryDialog(item["title"], item["content"].toString());
    }
  }

  void _showSummaryDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      )
    );
  }
}