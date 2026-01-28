import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeafLoadingWidget extends StatelessWidget {
  const LeafLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Leaf Icon with "floating on wind" animation
          const Icon(Icons.eco, size: 80, color: Colors.greenAccent)
              .animate(onPlay: (controller) => controller.repeat())
              .moveY(begin: 0, end: -20, duration: 2.seconds, curve: Curves.easeInOut)
              .then()
              .moveY(begin: -20, end: 0, duration: 2.seconds, curve: Curves.easeInOut)
              .rotate(begin: 0, end: 0.1, duration: 2.seconds)
              .then()
              .rotate(begin: 0.1, end: -0.1, duration: 2.seconds),
          
          const SizedBox(height: 20),
          
          Text(
            "Analyzing ecosystem...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2.seconds, color: Colors.greenAccent),
        ],
      ),
    );
  }
}
