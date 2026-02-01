import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';

class ScannerLoadingWidget extends StatefulWidget {
  final Uint8List? imageBytes;
  final String statusText; // Allow external control or use internal cycling

  const ScannerLoadingWidget({super.key, this.imageBytes, this.statusText = "Initializing..."});

  @override
  State<ScannerLoadingWidget> createState() => _ScannerLoadingWidgetState();
}

class _ScannerLoadingWidgetState extends State<ScannerLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Internal status cycle for "Matrix" feel
  final List<String> _statuses = [
    "Initializing Neuro-Link...",
    "Mapping 3D Geometry...",
    "Analyzing Carbon Fingerprint...",
    "Querying Eco-Database...",
    "Visualizing Impact...",
    "Finalizing Audit..."
  ];
  int _statusIndex = 0;

  @override
  void initState() {
    super.initState();
    // Looping scan effect (PingPong for back and forth "Xerox" style)
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
      
    // Rotate status text every 800ms
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statuses.length;
        });
      }
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Container instead of Scaffold for overlay usage
    return Container(
      color: Colors.black.withOpacity(0.95), // Deep dark overlay
      child: Stack(
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
                      aspectRatio: 1.0, 
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
                                  // Layer A: Original Image (Dimmed / Blueprint look)
                                  Image.memory(
                                    widget.imageBytes!,
                                    fit: BoxFit.contain,
                                    width: width,
                                    height: height,
                                    color: Colors.black.withOpacity(0.6),
                                    colorBlendMode: BlendMode.hardLight,
                                  ),

                                  // Layer B: Processed 3D Map Effect (Revealed "Xerox" style)
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
                                    left: scanPos - 2, 
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent,
                                        boxShadow: [
                                          BoxShadow(color: Colors.greenAccent.withOpacity(0.8), blurRadius: 20, spreadRadius: 2),
                                          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5, spreadRadius: 1),
                                        ]
                                      ),
                                    ),
                                  ),
                                  
                                  // Floating "Data Points" near the scan line
                                  if (_controller.value > 0.2 && _controller.value < 0.8)
                                    Positioned(
                                      left: scanPos + 10,
                                      top: height * 0.3,
                                      child: _dataPoint(),
                                    ),
                                  if (_controller.value > 0.4 && _controller.value < 0.9)
                                    Positioned(
                                      left: scanPos - 20,
                                      top: height * 0.6,
                                      child: _dataPoint(),
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

          // Real-time Update Panel (Bottom)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(30),
                       border: Border.all(color: Colors.greenAccent.withOpacity(0.5))
                     ),
                     child: Text(
                       _statuses[_statusIndex],
                       style: const TextStyle(
                         color: Colors.greenAccent, 
                         fontFamily: 'Courier', 
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                         letterSpacing: 1.5
                       ),
                     ).animate().fadeIn(),
                   ),
                   const SizedBox(height: 16),
                   SizedBox(
                     width: 200,
                     child: LinearProgressIndicator(
                       backgroundColor: Colors.white10,
                       color: Colors.greenAccent,
                       minHeight: 2,
                       value: null, // Indeterminate loading style
                     ),
                   )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _dataPoint() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(4)
      ),
      child: const Text(
        "OBJ_ID_24", 
        style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontFamily: 'Courier')
      ),
    ).animate().scale(duration: 200.ms).fadeOut(delay: 500.ms);
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
