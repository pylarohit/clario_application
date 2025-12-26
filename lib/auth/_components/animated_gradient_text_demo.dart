import 'package:flutter/material.dart';
import '../../components/animated_gradient_text.dart';

class AnimatedGradientTextDemo extends StatelessWidget {
  const AnimatedGradientTextDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8FDFFF).withValues(alpha: 0.12),
            offset: const Offset(0, -8),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 16,
            width: 1,
            color: Colors.grey.shade300,
          ),
          AnimatedGradientText(
            text: 'Introducing Clario',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
            colors: [
              Color(0xFFFFEB3B), // yellow-500
              Colors.white,
              Color(0xFFFFEB3B), // yellow-500
            ],
            duration: const Duration(seconds: 2),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}