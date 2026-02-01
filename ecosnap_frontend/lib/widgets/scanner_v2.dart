import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

class ScannerV2Widget extends StatefulWidget {
  final Uint8List? imageBytes;
  
  const ScannerV2Widget({super.key, this.imageBytes});

  @override
  State<ScannerV2Widget> createState() => _ScannerV2WidgetState();
}

class _ScannerV2WidgetState extends State<ScannerV2Widget> with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  
  // Simulated Analysis Steps
  final List<String> _analysisSteps = [
    "Initializing Optical Sensors...",
    "Detecting Object Boundaries...",
    "Analyzing Surface Texture...",
    "Estimating Carbon Emission...",
    "Querying Sustainability DB...",
    "Generating Recommendations..."
  ];
  
  // Track which steps are "done" for visual ticking
  final List<bool> _completedSteps = List.generate(6, (index) => false);

  @override
  void initState() {
    super.initState();
    
    // Main Laser Scan Loop (3 seconds per pass)
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
      
    // Background Pulse (Breathing effect)
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    // Sequence the checklist items
    _startChecklistSequence();
  }

  void _startChecklistSequence() async {
    for (int i = 0; i < _analysisSteps.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 600)); // Delay between steps
      if (mounted) {
        setState(() {
          _completedSteps[i] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF050505).withOpacity(0.95), // Deep Black Overlay
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Grid (Holographic Floor)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _HolographicGridPainter(pulse: _pulseController.value),
                  );
                },
              ),
            ),

            // 2. Main Content Area
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The "Eye" - Scanning Area
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        if (widget.imageBytes != null) ...[
                          // Layer A: "Blueprint" Mode (Grayscale + Edge detection look)
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.saturation), // Grayscale
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix([
                                -1,  0,  0, 0, 255,
                                 0, -1,  0, 0, 255,
                                 0,  0, -1, 0, 255,
                                 0,  0,  0, 1,   0,
                              ]), // Invert (Poor man's edge detect style)
                              child: Image.memory(
                                widget.imageBytes!,
                                fit: BoxFit.cover,
                                width: 300,
                                height: 300, 
                                opacity: const AlwaysStoppedAnimation(0.4),
                              ),
                            ),
                          ),

                          // Layer B: "Reality" Mode (Revealed by Laser)
                          AnimatedBuilder(
                            animation: _scanController,
                            builder: (context, child) {
                              return ClipRect(
                                clipper: _LaserScanClipper(_scanController.value),
                                child: Image.memory(
                                  widget.imageBytes!,
                                  fit: BoxFit.cover,
                                   width: 300,
                                   height: 300,
                                ),
                              );
                            },
                          ),
                          
                          // Layer C: Data Overlay on Image (Target Reticles)
                           _buildFloatingReticles(),
                        ] else
                          const Center(child: Text("Waiting for visual input...", style: TextStyle(color: Colors.greenAccent))),

                        // Layer D: The Laser Beam
                        AnimatedBuilder(
                          animation: _scanController,
                          builder: (context, _) {
                            return Positioned(
                              top: _scanController.value * 300,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent,
                                  boxShadow: [
                                    BoxShadow(color: Colors.greenAccent, blurRadius: 10, spreadRadius: 2),
                                    BoxShadow(color: Colors.white, blurRadius: 5, spreadRadius: 1), 
                                  ]
                                ),
                              ),
                            );
                          },
                        ),
                        
                        // Layer E: Scan Gradient Trail (Behind laser)
                        AnimatedBuilder(
                           animation: _scanController,
                           builder: (context, _) {
                             return Positioned(
                               top: _scanController.value * 300 - 50,
                               left: 0,
                               right: 0,
                               height: 50,
                               child: Container(
                                 decoration: BoxDecoration(
                                   gradient: LinearGradient(
                                     begin: Alignment.bottomCenter,
                                     end: Alignment.topCenter,
                                     colors: [
                                       Colors.greenAccent.withOpacity(0.3),
                                       Colors.transparent
                                     ]
                                   )
                                 ),
                               ),
                             );
                           }
                        )
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 3. Data Stream (Checklist)
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SYSTEM_ANALYSIS_LOG:",
                        style: TextStyle(
                          color: Colors.greenAccent, 
                          fontFamily: 'Courier', 
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._analysisSteps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final text = entry.value;
                        final isDone = _completedSteps[index];
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                isDone ? Icons.check_circle_outline : Icons.circle_outlined,
                                color: isDone ? Colors.greenAccent : Colors.white24,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isDone ? Colors.white : Colors.white38,
                                    fontFamily: 'Courier',
                                    fontSize: 12
                                  ),
                                ),
                              )
                            ],
                          ).animate(target: isDone ? 1 : 0).shimmer(duration: 500.ms),
                        );
                      }).toList(),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingReticles() {
     return Stack(
       children: [
         Positioned(
           top: 50, left: 50,
           child: _reticle(),
         ),
         Positioned(
           bottom: 80, right: 60,
           child: _reticle(),
         )
       ],
     );
  }
  
  Widget _reticle() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1),
      ),
      child: Center(child: Container(width: 4, height: 4, color: Colors.greenAccent)),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
    .scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2), duration: 1.seconds)
    .rotate(begin: 0, end: 0.25, duration: 2.seconds);
  }
}

class _LaserScanClipper extends CustomClipper<Rect> {
  final double progress;
  _LaserScanClipper(this.progress);

  @override
  Rect getClip(Size size) {
    // Reveal top to bottom
    return Rect.fromLTRB(0, 0, size.width, size.height * progress);
  }

  @override
  bool shouldReclip(covariant _LaserScanClipper oldClipper) => oldClipper.progress != progress;
}

class _HolographicGridPainter extends CustomPainter {
  final double pulse;
  _HolographicGridPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.05 + (pulse * 0.05))
      ..strokeWidth = 1;

    // Perspective Grid
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i - (size.width/2 - i)*0.5, size.height), paint);
    }
     for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicGridPainter oldDelegate) => oldDelegate.pulse != pulse;
}
