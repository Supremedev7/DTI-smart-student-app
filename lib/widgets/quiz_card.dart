import 'package:flutter/material.dart';

class QuizCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizCard({
    super.key,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? selectedIndex;
  bool isCorrect = false;

  void _checkAnswer(int index) {
    if (selectedIndex != null) return;
    setState(() {
      selectedIndex = index;
      isCorrect = index == widget.correctIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final optionTextColor = isDark ? Colors.grey.shade300 : const Color(0xFF334155);

    return Container(
      width: 320,
      height: 480,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEC4899).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.help_outline, color: Color(0xFFEC4899), size: 20),
              ),
              const SizedBox(width: 12),
              const Text("QUESTION", style: TextStyle(color: Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.question,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, height: 1.4),
          ),
          const Spacer(),
          ...List.generate(widget.options.length, (index) {
            bool isSelected = selectedIndex == index;
            bool isThisCorrect = index == widget.correctIndex;
            
            Color itemColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
            if (selectedIndex != null) {
              if (isThisCorrect) itemColor = const Color(0xFF10B981).withOpacity(0.2);
              else if (isSelected) itemColor = Colors.red.withOpacity(0.1);
            }

            return GestureDetector(
              onTap: () => _checkAnswer(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: itemColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedIndex != null && isThisCorrect 
                      ? const Color(0xFF10B981) 
                      : (isSelected && !isCorrect ? Colors.red : Colors.transparent),
                    width: 2
                  ),
                ),
                child: Row(
                  children: [
                    Text(String.fromCharCode(65 + index), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.options[index], 
                        style: TextStyle(fontWeight: FontWeight.w500, color: optionTextColor)
                      )
                    ),
                    if (selectedIndex != null && isThisCorrect) const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                    if (isSelected && !isCorrect) const Icon(Icons.cancel, color: Colors.red, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}