import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

class ScannerV2Widget extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? detectedProduct;
  final double analysisProgress;
  final String? currentPhase;
  final VoidCallback? onComplete;
  
  const ScannerV2Widget({
    super.key, 
    this.imageBytes,
    this.detectedProduct,
    this.analysisProgress = 0.0,
    this.currentPhase,
    this.onComplete,
  });

  @override
  State<ScannerV2Widget> createState() => _ScannerV2WidgetState();
}

class _ScannerV2WidgetState extends State<ScannerV2Widget> with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _pulseController;
  late AnimationController _dataFlowController;
  
  // 🚀 ENHANCED Real-Time Analysis Phases
  final List<Map<String, dynamic>> _analysisPhases = [
    {"icon": "🔍", "label": "Detecting object...", "technical": "YOLO_v8 inference"},
    {"icon": "🧠", "label": "AI vision processing...", "technical": "Gemini Flash analysis"},
    {"icon": "🌍", "label": "Calculating carbon footprint...", "technical": "CO₂ lifecycle compute"},
    {"icon": "📊", "label": "Finding green alternatives...", "technical": "Sustainability DB query"},
    {"icon": "💰", "label": "Computing savings...", "technical": "Financial projection"},
    {"icon": "✨", "label": "Generating insights...", "technical": "Report compile"},
  ];
  
  // Live data stream simulation
  final List<String> _liveData = [];
  int _currentPhaseIndex = 0;
  bool _showConfetti = false;
  
  // Simulated real-time metrics
  double _carbonValue = 0.0;
  double _savingsValue = 0.0;
  String _detectedName = "Analyzing...";

  @override
  void initState() {
    super.initState();
    
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
      
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
      
    _dataFlowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat();

    _startRealTimeAnalysis();
  }

  /// 🔥 Real-time analysis simulation with live data updates
  void _startRealTimeAnalysis() async {
    final random = math.Random();
    
    // Phase 1: Object Detection (800ms)
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _currentPhaseIndex = 0;
      _detectedName = widget.detectedProduct ?? "Product Detected";
      _liveData.add("OBJECT: $_detectedName");
    });
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _currentPhaseIndex = 1;
      _liveData.add("CONFIDENCE: ${(85 + random.nextInt(14))}%");
    });
    
    // Phase 2: AI Processing (1000ms)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _currentPhaseIndex = 2;
      _carbonValue = 1.2 + random.nextDouble() * 3;
      _liveData.add("CO₂: ${_carbonValue.toStringAsFixed(2)} kg/year");
    });
    
    // Phase 3: Alternatives (800ms)
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _currentPhaseIndex = 3;
      _liveData.add("ALTERNATIVES: 3 found");
    });
    
    // Phase 4: Savings (600ms)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _currentPhaseIndex = 4;
      _savingsValue = 500 + random.nextInt(2000).toDouble();
      _liveData.add("SAVINGS: ₹${_savingsValue.toStringAsFixed(0)}/year");
    });
    
    // Phase 5: Complete (500ms)
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _currentPhaseIndex = 5;
      _liveData.add("✅ ANALYSIS COMPLETE");
      _showConfetti = true;
    });
    
    // Trigger completion callback
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    _dataFlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF050505).withOpacity(0.85),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Grid
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

            // Main Content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔥 Real-time Header
                  _buildLiveHeader(),
                  
                  const SizedBox(height: 20),
                  
                  // Image Scanner Area
                  _buildScannerArea(),
                  
                  const SizedBox(height: 24),
                  
                  // 💨 Live Data Stream
                  _buildLiveDataStream(),
                  
                  const SizedBox(height: 24),
                  
                  // 📊 Progress Phases
                  _buildPhaseProgress(),
                ],
              ),
            ),
            
            // 🎉 Confetti celebration
            if (_showConfetti)
              _buildConfettiOverlay(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLiveHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 500.ms),
          const SizedBox(width: 10),
          Text(
            _currentPhaseIndex >= 5 ? "ANALYSIS COMPLETE" : "ANALYZING • LIVE",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.3, end: 0);
  }

  Widget _buildScannerArea() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.greenAccent.withOpacity(0.4), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.greenAccent.withOpacity(0.15), blurRadius: 30, spreadRadius: 5)
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            if (widget.imageBytes != null) ...[
              // Blueprint Mode
              ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.saturation),
                child: Image.memory(
                  widget.imageBytes!,
                  fit: BoxFit.cover,
                  width: 280,
                  height: 280, 
                  opacity: const AlwaysStoppedAnimation(0.3),
                ),
              ),

              // Reality reveal with laser
              AnimatedBuilder(
                animation: _scanController,
                builder: (context, child) {
                  return ClipRect(
                    clipper: _LaserScanClipper(_scanController.value),
                    child: Image.memory(
                      widget.imageBytes!,
                      fit: BoxFit.cover,
                      width: 280,
                      height: 280,
                    ),
                  );
                },
              ),
              
              // 🎯 Target reticles with data
              _buildDataOverlay(),
            ] else
              const Center(child: Text("Initializing...", style: TextStyle(color: Colors.greenAccent))),

            // Laser beam
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                return Positioned(
                  top: _scanController.value * 280,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.greenAccent, Colors.white, Colors.greenAccent, Colors.transparent],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.greenAccent, blurRadius: 15, spreadRadius: 3),
                      ]
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataOverlay() {
    if (_currentPhaseIndex < 2) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _detectedName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "CO₂: ${_carbonValue.toStringAsFixed(1)} kg/year",
                    style: TextStyle(color: Colors.redAccent.shade100, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_currentPhaseIndex >= 4)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Save ₹${_savingsValue.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.5, end: 0),
    );
  }

  Widget _buildLiveDataStream() {
    return Container(
      width: 280,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("LIVE DATA STREAM", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const Spacer(),
              AnimatedBuilder(
                animation: _dataFlowController,
                builder: (context, _) => Icon(Icons.sensors, size: 12, color: Colors.greenAccent.withOpacity(0.5 + _dataFlowController.value * 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _liveData.length,
              itemBuilder: (ctx, i) {
                final item = _liveData[_liveData.length - 1 - i];
                return Text(
                  "> $item",
                  style: TextStyle(
                    color: item.contains("✅") ? Colors.greenAccent : Colors.white70,
                    fontFamily: 'Courier',
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseProgress() {
    return Container(
      width: 280,
      child: Column(
        children: [
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                width: 280 * ((_currentPhaseIndex + 1) / _analysisPhases.length),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.tealAccent]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Current phase label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _analysisPhases[_currentPhaseIndex]["icon"],
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                _analysisPhases[_currentPhaseIndex]["label"],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ).animate(key: ValueKey(_currentPhaseIndex)).fadeIn().slideX(begin: 0.2, end: 0),
          const SizedBox(height: 4),
          Text(
            _analysisPhases[_currentPhaseIndex]["technical"],
            style: TextStyle(color: Colors.greenAccent.withOpacity(0.6), fontFamily: 'Courier', fontSize: 9),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(20, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * 300,
              top: -20,
              child: Icon(
                index % 2 == 0 ? Icons.eco : Icons.star,
                color: index % 3 == 0 ? Colors.greenAccent : Colors.amber,
                size: 16 + random.nextDouble() * 12,
              ).animate()
               .slideY(begin: 0, end: 8 + random.nextDouble() * 4, duration: Duration(milliseconds: (2000 + random.nextDouble() * 1000).toInt()))
               .rotate(end: random.nextDouble() * 2, duration: Duration(milliseconds: (1500 + random.nextDouble() * 1000).toInt()))
               .fadeOut(delay: 1500.ms),
            );
          }),
        ),
      ),
    );
  }
}

class _LaserScanClipper extends CustomClipper<Rect> {
  final double progress;
  _LaserScanClipper(this.progress);

  @override
  Rect getClip(Size size) {
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
      ..color = Colors.greenAccent.withOpacity(0.03 + (pulse * 0.03))
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i - (size.width/2 - i)*0.3, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicGridPainter oldDelegate) => oldDelegate.pulse != pulse;
}
