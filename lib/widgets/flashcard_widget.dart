import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

class FlashcardWidget extends StatelessWidget {
  final String question;
  final String answer;

  const FlashcardWidget({
    super.key,
    required this.question,
    required this.answer,
  });

  static const double cardWidth = 300;
  static const double cardHeight = 420;

  Widget _buildCornerIndex(String letter, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          letter,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'serif',
            height: 1.0,
          ),
        ),
        Icon(icon, size: 18, color: color),
      ],
    );
  }

  Widget _buildFront(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final shadowColor = isDark ? Colors.black54 : Colors.black.withOpacity(0.12);
    
    final Color themeColor = Colors.red.shade700;
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardColor, // Dynamic background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14, left: 14, right: 14, bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: themeColor.withOpacity(0.8), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          Positioned(
            top: 24, left: 24,
            child: _buildCornerIndex("Q", themeColor, Icons.help_outline),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Text(
                question,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor, // Dynamic text color
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final shadowColor = isDark ? Colors.black54 : Colors.black.withOpacity(0.12);
    
    final Color themeColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A); // Adjust blue based on mode
    final Color tintColor = isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFF0F9FF);
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardColor, // Dynamic background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 14, left: 14, right: 14, bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                color: tintColor, // Dynamic inner tint
                border: Border.all(color: themeColor.withOpacity(0.8), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          Positioned(
            top: 24, left: 24,
            child: _buildCornerIndex("A", themeColor, Icons.lightbulb_outline),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: textColor, // Dynamic text color
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      direction: FlipDirection.HORIZONTAL,
      front: _buildFront(context),
      back: _buildBack(context),
    );
  }
}