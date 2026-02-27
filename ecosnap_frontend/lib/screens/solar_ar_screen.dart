import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class SolarARScreen extends StatefulWidget {
  final Map<String, dynamic>? solarData;
  final Uint8List? imageBytes;
  
  const SolarARScreen({super.key, this.solarData, this.imageBytes});

  @override
  State<SolarARScreen> createState() => _SolarARScreenState();
}

enum _SolarPhase { scanning, analyzing, active }

class _SolarARScreenState extends State<SolarARScreen> with TickerProviderStateMixin {
  _SolarPhase _phase = _SolarPhase.scanning;

  // Data from analysis
  double _potentialKw = 5.0;
  double _monthlySavings = 0;
  double _paybackYears = 0;
  double _roofPitch = 18.5;
  double _azimuth = 175.0;
  double _irradiance = 5.2;
  int _recommendedPanels = 12;
  String _viability = 'Good';
  String _recommendation = '';
  int _viabilityScore = 75;
  List<String> _detectedObjects = [];

  // Roof polygon (normalised 0–1)
  List<Offset> _roofPolygon = [];

  // Animations
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _parseData();

    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

    _startScan();
  }

  void _parseData() {
    final d = widget.solarData ?? {};
    final sv = d['solar_viability'] ?? d['solar_potential'] ?? {};
    final fin = d['financial_analysis'] as Map? ?? {};
    final sp = d['solar_potential'] as Map? ?? {};

    // Detected objects for context
    final objects = d['detected_objects'] as List? ?? [];
    _detectedObjects = objects.map<String>((o) => (o is Map ? o['name'] : o).toString()).toList();

    String pk = (sv['potential_kw'] ?? sv['estimated_capacity_kw'] ?? '5.0kW').toString();
    _potentialKw = double.tryParse(pk.replaceAll('kW', '').replaceAll(' ', '')) ?? 5.0;
    _recommendedPanels = (sv['recommended_panels'] as num?)?.toInt() ?? (_potentialKw / 0.4).ceil();
    _monthlySavings = (fin['monthly_savings_inr'] as num?)?.toDouble() ?? (_potentialKw * 1625);
    _paybackYears = (fin['payback_years'] as num?)?.toDouble() ?? (fin['payback_period_years'] as num?)?.toDouble() ?? 5.5;
    _roofPitch = (sv['roof_pitch'] as num?)?.toDouble() ?? 18.5;
    _azimuth = (sv['azimuth'] as num?)?.toDouble() ?? 175.0;
    _irradiance = (sp['irradiance_kwh_m2_day'] as num?)?.toDouble() ?? 5.2;
    _viability = sv['viability'] ?? 'Good';
    _viabilityScore = (sv['viability_score'] as num?)?.toInt() ?? (sv['score'] as num?)?.toInt() ?? 75;
    _recommendation = d['recommendation']?.toString() ?? '';

    // Build roof polygon from data or default
    final rawPoly = d['roof_polygon'] as List?;
    if (rawPoly != null && rawPoly.isNotEmpty) {
      _roofPolygon = rawPoly.map<Offset>((p) => Offset(
        (p['x'] as num?)?.toDouble() ?? 0.5,
        (p['y'] as num?)?.toDouble() ?? 0.5,
      )).toList();
    } else {
      // Smart default — typical roof in center-top of frame
      _roofPolygon = const [
        Offset(0.15, 0.12), Offset(0.50, 0.06), Offset(0.85, 0.12),
        Offset(0.88, 0.50), Offset(0.12, 0.52),
      ];
    }
  }

  void _startScan() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _phase = _SolarPhase.analyzing);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _phase = _SolarPhase.active);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Captured image (full bleed)
          Positioned.fill(
            child: widget.imageBytes != null
                ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xFF1a1a2e), Color(0xFF0a0f1a)],
                      ),
                    ),
                  ),
          ),

          // 2. Scanning overlay
          if (_phase == _SolarPhase.scanning)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _scanCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ScanOverlayPainter(progress: _scanCtrl.value, color: Colors.amberAccent),
                ),
              ),
            ),

          // 2b. Analyzing state — detected objects flash
          if (_phase == _SolarPhase.analyzing)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.3))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 400.ms).fadeOut(duration: 400.ms),
            ),

          // 3. Solar Potential Heatmap on roof
          if (_phase == _SolarPhase.active)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseCtrl, _shimmerCtrl]),
                builder: (_, __) => CustomPaint(
                  painter: _SolarHeatmapPainter(
                    roofPolygon: _roofPolygon,
                    pulse: _pulseCtrl.value,
                    shimmer: _shimmerCtrl.value,
                    irradiance: _irradiance,
                    viabilityScore: _viabilityScore,
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms),
            ),

          // 4. Header
          _buildHeader(),

          // 5. Detected objects chips (subtle)
          if (_phase == _SolarPhase.active && _detectedObjects.isNotEmpty)
            Positioned(
              top: 110, left: 16, right: 16,
              child: Wrap(
                spacing: 6, runSpacing: 4,
                children: _detectedObjects.take(5).map((obj) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(obj, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                )).toList(),
              ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
            ),

          // 6. Bottom stats bar
          if (_phase == _SolarPhase.active)
            _buildBottom(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 50, left: 16, right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _phase == _SolarPhase.scanning ? 'SCANNING ROOF...'
                          : _phase == _SolarPhase.analyzing ? 'ANALYZING...'
                          : 'SOLAR POTENTIAL',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                      if (_phase == _SolarPhase.active)
                        Text(
                          '${_roofPitch.toStringAsFixed(0)}° pitch • ${_azimuth.toStringAsFixed(0)}° azimuth • ${_irradiance.toStringAsFixed(1)} kWh/m²/day',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                        ),
                    ],
                  ),
                ),
                if (_phase == _SolarPhase.active)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _viabilityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _viabilityColor.withOpacity(0.4)),
                    ),
                    child: Text('${_potentialKw.toStringAsFixed(1)} kW', style: TextStyle(color: _viabilityColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _viabilityColor => _viabilityScore > 70 ? Colors.greenAccent : _viabilityScore > 40 ? Colors.amberAccent : Colors.redAccent;

  Widget _buildBottom() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _stat('${_recommendedPanels}', 'Panels', Icons.grid_view),
                    _stat('₹${(_monthlySavings / 1000).toStringAsFixed(1)}K', '/month', Icons.savings),
                    _stat('${_paybackYears.toStringAsFixed(1)}yr', 'Payback', Icons.timer_outlined),
                  ],
                ),
                if (_recommendation.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amberAccent.withOpacity(0.15)),
                    ),
                    child: Text(
                      _recommendation,
                      style: const TextStyle(color: Colors.white60, fontSize: 10, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(context); },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(child: Text('VIEW FULL REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutExpo, duration: 700.ms),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(child: Column(children: [
      Icon(icon, color: Colors.white38, size: 16), const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]));
  }
}

// ─── PAINTERS ─────────────────────────────────────────────────

/// Shared scanning overlay with grid + sweep line
class _ScanOverlayPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScanOverlayPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    // Sweep line
    canvas.drawLine(
      Offset(0, y), Offset(size.width, y),
      Paint()
        ..shader = LinearGradient(colors: [Colors.transparent, color.withOpacity(0.5), Colors.transparent])
            .createShader(Rect.fromLTWH(0, y - 2, size.width, 4))
        ..strokeWidth = 2,
    );
    // Subtle grid above sweep
    final gp = Paint()..color = color.withOpacity(0.03)..strokeWidth = 0.5;
    for (double gy = 0; gy < y; gy += size.height / 20) {
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), gp);
    }
    for (double gx = 0; gx < size.width; gx += size.width / 12) {
      canvas.drawLine(Offset(gx, 0), Offset(gx, y), gp);
    }
    // Corner brackets
    _drawBrackets(canvas, size, color.withOpacity(0.3));
  }

  void _drawBrackets(Canvas canvas, Size size, Color c) {
    const l = 25.0;
    final p = Paint()..color = c..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(20, 20), const Offset(20 + l, 20), p);
    canvas.drawLine(const Offset(20, 20), const Offset(20, 20 + l), p);
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20 - l, 20), p);
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20, 20 + l), p);
    canvas.drawLine(Offset(20, size.height - 20), Offset(20 + l, size.height - 20), p);
    canvas.drawLine(Offset(20, size.height - 20), Offset(20, size.height - 20 - l), p);
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20 - l, size.height - 20), p);
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20, size.height - 20 - l), p);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) => old.progress != progress;
}

/// Solar heatmap — irradiance zones mapped to roof polygon
class _SolarHeatmapPainter extends CustomPainter {
  final List<Offset> roofPolygon;
  final double pulse;
  final double shimmer;
  final double irradiance;
  final int viabilityScore;
  _SolarHeatmapPainter({required this.roofPolygon, required this.pulse, required this.shimmer, required this.irradiance, required this.viabilityScore});

  @override
  void paint(Canvas canvas, Size size) {
    if (roofPolygon.isEmpty) return;

    final mapped = roofPolygon.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();
    final roofPath = Path()..addPolygon(mapped, true);
    final bounds = roofPath.getBounds();

    // 1. Roof boundary — dashed edge-detection style
    canvas.drawPath(roofPath, Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);

    // 2. Clipped heatmap inside roof
    canvas.save();
    canvas.clipPath(roofPath);

    // Gradient heatmap: top of roof = less sun (shadow), bottom = more sun
    final heatColor = viabilityScore > 70 ? Colors.greenAccent : viabilityScore > 40 ? Colors.amber : Colors.redAccent;
    canvas.drawRect(bounds, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.06 + pulse * 0.02),
          heatColor.withOpacity(0.10 + pulse * 0.03),
          heatColor.withOpacity(0.18 + pulse * 0.04),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(bounds));

    // Radial hotspot — best zone (center-bottom of roof)
    final hotspot = Offset(bounds.center.dx, bounds.top + bounds.height * 0.6);
    final hotR = bounds.width * 0.3;
    canvas.drawCircle(hotspot, hotR, Paint()
      ..shader = RadialGradient(colors: [
        heatColor.withOpacity(0.20 + pulse * 0.06),
        heatColor.withOpacity(0.03),
        Colors.transparent,
      ], stops: const [0.0, 0.55, 1.0])
        .createShader(Rect.fromCircle(center: hotspot, radius: hotR)));

    // Shimmer sweep across roof
    final sweepX = bounds.left + bounds.width * shimmer;
    canvas.drawLine(
      Offset(sweepX, bounds.top), Offset(sweepX, bounds.bottom),
      Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = bounds.width * 0.05,
    );

    canvas.restore();

    // 3. Zone labels
    _label(canvas, hotspot, 'BEST ZONE', heatColor, 10);
    _label(canvas, Offset(bounds.center.dx, bounds.top + bounds.height * 0.15), 'MODERATE', Colors.amber.withOpacity(0.8), 9);

    // 4. Corner pins
    for (final p in mapped) {
      canvas.drawCircle(p, 3.5, Paint()..color = Colors.white.withOpacity(0.5));
      canvas.drawCircle(p, 1.5, Paint()..color = heatColor);
    }

    // 5. Irradiance annotation at bottom-right of roof
    _label(canvas, Offset(bounds.right - 5, bounds.bottom + 14), '${irradiance.toStringAsFixed(1)} kWh/m²/day', Colors.white60, 8);
  }

  void _label(Canvas canvas, Offset pos, String text, Color c, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: c, fontSize: fs, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    final bg = RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: tp.width + 12, height: tp.height + 6), const Radius.circular(4));
    canvas.drawRRect(bg, Paint()..color = Colors.black.withOpacity(0.5));
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_SolarHeatmapPainter old) => old.pulse != pulse || old.shimmer != shimmer;
}
