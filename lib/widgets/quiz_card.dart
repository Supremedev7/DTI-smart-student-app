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

  int? selected;

  Widget optionButton(int index, String text) {

    Color color = Colors.grey.shade200;

    if (selected != null) {
      if (index == widget.correctIndex) {
        color = Colors.green.shade200;
      } else if (index == selected) {
        color = Colors.red.shade200;
      }
    }

    return GestureDetector(
      onTap: () {
        if (selected != null) return;

        setState(() {
          selected = index;
        });
      },

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),

        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),

        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Center(

      child: SizedBox(
        width: 320,

        child: AspectRatio(
          aspectRatio: 5 / 7,

          child: Container(

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                )
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  widget.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        widget.options.length,
                        (i) => optionButton(i, widget.options[i]),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}