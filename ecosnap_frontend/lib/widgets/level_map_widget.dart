import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LevelMapWidget extends StatelessWidget {
  final int currentLevel; // 1-based index of the highest unlocked level
  final Map<int, int> starsPerLevel; // Map of levelId -> stars (0-3)
  final Function(int) onLevelTap;

  // Hardcoded positions for a winding path (x: 0.0-1.0, y: vertical offset)
  // We'll scale y in the painter to create distance
  static const List<Offset> _nodePositions = [
    Offset(0.5, 0.0),   // Level 1 (Start)
    Offset(0.2, 0.15),  // Level 2 (Left)
    Offset(0.4, 0.3),   // Level 3
    Offset(0.8, 0.45),  // Level 4 (Right)
    Offset(0.6, 0.6),   // Level 5
    Offset(0.3, 0.75),  // Level 6 (Left)
    Offset(0.5, 0.9),   // Level 7
    Offset(0.8, 1.05),  // Level 8 (Right) - extends scroll
    Offset(0.5, 1.25),  // Level 9
    Offset(0.2, 1.45),  // Level 10
  ];

  const LevelMapWidget({
    Key? key,
    required this.currentLevel,
    required this.starsPerLevel,
    required this.onLevelTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: 1000, // Fixed height specifically for this map logic
        width: double.infinity,
        child: Stack(
          children: [
            // 1. Background Environment (Sky/Grass vibe)
            Positioned.fill(
              child: CustomPaint(
                painter: MapBackgroundPainter(),
              ),
            ),
            
            // 2. The Path
            Positioned.fill(
              child: CustomPaint(
                painter: PathPainter(positions: _nodePositions),
              ),
            ),

            // 3. Level Nodes
            ...List.generate(_nodePositions.length, (index) {
              final levelId = index + 1;
              final pos = _nodePositions[index];
              return Positioned(
                left: pos.dx * (MediaQuery.of(context).size.width - 80) + 10, // simple scaling
                top: pos.dy * 600 + 50, // simple scaling vertical
                child: _buildLevelNode(context, levelId),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelNode(BuildContext context, int levelId) {
    bool isLocked = levelId > currentLevel + 1; // Unlock next level
    bool isCurrent = levelId == currentLevel + 1;
    bool isCompleted = levelId <= currentLevel;
    int stars = starsPerLevel[levelId] ?? 0;

    return GestureDetector(
      onTap: () {
        if (!isLocked) onLevelTap(levelId);
      },
      child: Column(
        children: [
          // Stars (only if completed/unlocked)
          if (!isLocked)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Icon(
                  Icons.star,
                  size: 16,
                  color: index < stars ? Colors.amber : Colors.black26,
                );
              }),
            ).animate().scale(),

          const SizedBox(height: 4),

          // The Node
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked 
                  ? Colors.grey.shade700 
                  : (isCompleted ? Colors.greenAccent : Colors.orangeAccent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: isCurrent ? 15 : 5,
                  offset: const Offset(0, 4),
                ),
                if (isCurrent)
                  BoxShadow(color: Colors.orangeAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock, color: Colors.white38)
                  : Text(
                      "$levelId",
                      style: const TextStyle(
                        fontFamily: "Roboto", // or any fun font
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ).animate(target: isCurrent ? 1 : 0).shimmer(duration: 1500.ms),
        ],
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Offset> positions;

  PathPainter({required this.positions});

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 // Thicker path
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round; // Dashed effect could be fun too

    // Dotted line paint
    final dotPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // We need to scale the normalized input positions to actual canvas size
    // Using same logic as Positioned widget for consistency:
    // x range: ~0.0 to 1.0 mapped to width
    // y range: ~0.0 to ~1.5 mapped to height (approx 600 unit scale + offset)
    
    Offset getActualPos(Offset norm) {
        return Offset(
            norm.dx * (size.width - 80) + 40, // +40 centering offset (half of node width roughly)
            norm.dy * 600 + 80 // +80 centering offset
        );
    }

    final path = Path();
    path.moveTo(getActualPos(positions[0]).dx, getActualPos(positions[0]).dy);

    for (int i = 0; i < positions.length - 1; i++) {
      final p1 = getActualPos(positions[i]);
      final p2 = getActualPos(positions[i+1]);

      // Simple curve
      // Control point logic: randomizing or midway perpendicular can be complex
      // Let's use a simple quadratic bezier with control point slightly offset
      final controlPoint = Offset(
        (p1.dx + p2.dx) / 2 + (i % 2 == 0 ? 50 : -50), // Zig-zag curve
        (p1.dy + p2.dy) / 2,
      );
      
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.dx, p2.dy);
    }

    // Draw base thick empty path
    canvas.drawPath(path, paint);

    // Draw dashes (manual simplified approach for "dots")
    // A proper DashPath requires PathMetric, let's keep it simple style:
    // Just drawing the same path thinner and lighter on top
    canvas.drawPath(path, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Just some decorative elements or gradients can go here
    // Currently doing nothing as the screen has a background color
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
