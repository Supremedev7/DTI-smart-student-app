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

  // Tall rectangular shape (near imitation of a playing card)
  static const double cardWidth = 300;
  static const double cardHeight = 420;

  /// Helper to build the top-left corner indicator
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

  /// FRONT: The Question Card
  Widget _buildFront() {
    final Color themeColor = Colors.red.shade700;
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          // Classic Inner Border (for that playing card feel)
          Positioned(
            top: 14, left: 14, right: 14, bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: themeColor.withOpacity(0.8), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Top Left Corner Only (No bottom mirrored icon)
          Positioned(
            top: 24, left: 24,
            child: _buildCornerIndex("Q", themeColor, Icons.help_outline),
          ),

          // Center Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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

  /// BACK: The Answer Card
  Widget _buildBack() {
    final Color themeColor = const Color(0xFF1E3A8A); // Deep Navy Blue
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          // Subtle tinted background and inner border
          Positioned(
            top: 14, left: 14, right: 14, bottom: 14,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF), // Very light blue tint
                border: Border.all(color: themeColor.withOpacity(0.8), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Top Left Corner Only (No bottom mirrored icon)
          Positioned(
            top: 24, left: 24,
            child: _buildCornerIndex("A", themeColor, Icons.lightbulb_outline),
          ),

          // Center Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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
      front: _buildFront(),
      back: _buildBack(),
    );
  }
}