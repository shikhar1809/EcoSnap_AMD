import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class ScannerLoadingWidget extends StatefulWidget {
  final Uint8List? imageBytes;

  const ScannerLoadingWidget({super.key, this.imageBytes});

  @override
  State<ScannerLoadingWidget> createState() => _ScannerLoadingWidgetState();
}

class _ScannerLoadingWidgetState extends State<ScannerLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Scan takes 3 seconds, same as the delay in home_screen
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background - Dark Grid for "3D Space" feel
          CustomPaint(
            painter: GridPainter(),
            child: Container(),
          ),

          Center(
            child: widget.imageBytes == null
                ? const Text("Initializing Scanner...", style: TextStyle(color: Colors.white))
                : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AspectRatio(
                      aspectRatio: 1.0, // Assuming square-ish focus for now, or fit box
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final double width = constraints.maxWidth;
                              final double height = constraints.maxHeight;
                              final double scanPos = width * _controller.value;

                              return Stack(
                                children: [
                                  // 1. Original Image (Unscanned - Right side)
                                  // We display the full image, but revealed only on the RIGHT of the bar? 
                                  // Actually, "Xerox" style usually turns the image FROM something TO something.
                                  // Let's say: UNPROCESSED (Dim) -> PROCESSED (Green Wireframe/Hologram)
                                  
                                  // Layer A: Unprocessed Image (Dimmed)
                                  Image.memory(
                                    widget.imageBytes!,
                                    fit: BoxFit.contain,
                                    width: width,
                                    height: height,
                                    color: Colors.black.withOpacity(0.5),
                                    colorBlendMode: BlendMode.darken,
                                  ),

                                  // Layer B: Processed 3D Map Effect (Revealed from Left)
                                  ClipRect(
                                    clipper: HorizontalScanClipper(_controller.value),
                                    child: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(Colors.greenAccent, BlendMode.modulate),
                                      child: Stack(
                                        children: [
                                          Image.memory(
                                            widget.imageBytes!,
                                            fit: BoxFit.contain,
                                            width: width,
                                            height: height,
                                          ),
                                          // Overlay a grid on the "scanned" part to make it look 3D mapped
                                          CustomPaint(
                                            size: Size(width, height),
                                            painter: OverlayGridPainter(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Layer C: The Scanner Light Bar
                                  Positioned(
                                    left: scanPos - 10, // Centered on the exact line
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 20,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.greenAccent.withOpacity(0.0),
                                            Colors.greenAccent.withOpacity(0.8),
                                            Colors.greenAccent.withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.greenAccent.withOpacity(0.5),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      ),
                                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
                                  ),
                                  
                                  // Floating Elements near the scan line to simulate "capturing"
                                  Positioned(
                                    left: scanPos + 5,
                                    top: height * 0.2,
                                    child: const Icon(Icons.add, color: Colors.greenAccent, size: 10)
                                        .animate().scale(duration: 0.5.seconds),
                                  ),
                                   Positioned(
                                    left: scanPos + 5,
                                    top: height * 0.5,
                                    child: const Icon(Icons.add, color: Colors.greenAccent, size: 10)
                                        .animate(delay: 0.2.seconds).scale(duration: 0.5.seconds),
                                  ),
                                   Positioned(
                                    left: scanPos + 5,
                                    top: height * 0.8,
                                    child: const Icon(Icons.add, color: Colors.greenAccent, size: 10)
                                        .animate(delay: 0.4.seconds).scale(duration: 0.5.seconds),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                ),
          ),

          // Bottom Progress Panel
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _controller.value < 0.3 ? "Identifying objects..." :
                          _controller.value < 0.6 ? "Calculating dimensions..." :
                          _controller.value < 0.9 ? "Mapping heat signatures..." : "Finalizing...",
                          style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontWeight: FontWeight.bold)
                        ),
                        Text("${(_controller.value * 100).toInt()}%", style: const TextStyle(color: Colors.white)),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _controller.value,
                  backgroundColor: Colors.white10,
                  color: Colors.greenAccent,
                  minHeight: 4,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class HorizontalScanClipper extends CustomClipper<Rect> {
  final double progress;

  HorizontalScanClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(covariant HorizontalScanClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OverlayGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw simple grid on objects
     for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
     for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
