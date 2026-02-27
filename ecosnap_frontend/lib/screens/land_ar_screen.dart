import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class LandARScreen extends StatefulWidget {
  final Map<String, dynamic>? landData;
  final Uint8List? imageBytes;

  const LandARScreen({super.key, this.landData, this.imageBytes});

  @override
  State<LandARScreen> createState() => _LandARScreenState();
}

enum _LandPhase { scanning, analyzing, active }
enum _LandMode { solar, agrivoltaic, wind }

class _LandARScreenState extends State<LandARScreen> with TickerProviderStateMixin {
  _LandPhase _phase = _LandPhase.scanning;
  _LandMode _mode = _LandMode.solar;

  double _areaSqm = 10000;
  double _areaAcres = 2.5;
  double _solarCapacityKw = 100;
  double _annualRevenue = 450000;
  String _soilType = '';
  String _viability = 'High';
  String _recommendation = '';
  List<String> _detectedObjects = [];

  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _parseData();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _startScan();
  }

  void _parseData() {
    final d = widget.landData ?? {};
    final land = d['land_analysis'] ?? {};
    final energy = d['energy_potential'] ?? {};
    final fin = d['financial_analysis'] as Map? ?? {};

    final objects = d['detected_objects'] as List? ?? [];
    _detectedObjects = objects.map<String>((o) => (o is Map ? o['name'] : o).toString()).toList();

    _areaSqm = (land['area_sqm'] as num?)?.toDouble() ?? (land['estimated_area_sqm'] as num?)?.toDouble() ?? 10000;
    _areaAcres = _areaSqm / 4047;
    _soilType = (land['soil_type'] ?? '').toString();
    _viability = (energy['viability'] ?? land['viability'] ?? 'High').toString();
    _solarCapacityKw = (energy['solar_capacity_kw'] as num?)?.toDouble() ?? (_areaSqm * 0.01);
    _annualRevenue = (fin['annual_revenue_inr'] as num?)?.toDouble() ?? (_solarCapacityKw * 4500);
    _recommendation = (d['recommendation'] ?? '').toString();
  }

  void _startScan() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _phase = _LandPhase.analyzing);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _phase = _LandPhase.active);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() { _scanCtrl.dispose(); _pulseCtrl.dispose(); _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.imageBytes != null
                ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF0a0f1a)),
          ),
          if (_phase == _LandPhase.scanning)
            Positioned.fill(child: AnimatedBuilder(animation: _scanCtrl, builder: (_, __) => CustomPaint(painter: _LandScanPainter(progress: _scanCtrl.value)))),
          if (_phase == _LandPhase.analyzing)
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3)).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 400.ms).fadeOut(duration: 400.ms)),

          // Main overlay
          if (_phase == _LandPhase.active)
            Positioned.fill(child: AnimatedBuilder(
              animation: Listenable.merge([_pulseCtrl, _shimmerCtrl]),
              builder: (_, __) => CustomPaint(painter: _LandZonePainter(
                pulse: _pulseCtrl.value, shimmer: _shimmerCtrl.value, mode: _mode,
              )),
            ).animate().fadeIn(duration: 800.ms)),

          _buildHeader(),

          if (_phase == _LandPhase.active && _detectedObjects.isNotEmpty)
            Positioned(
              top: 110, left: 16, right: 16,
              child: Wrap(
                spacing: 6, runSpacing: 4,
                children: _detectedObjects.take(5).map((obj) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                  child: Text(obj, style: const TextStyle(color: Colors.white54, fontSize: 9)),
                )).toList(),
              ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
            ),

          if (_phase == _LandPhase.active) _buildBottom(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hColor = _viability == 'High' ? Colors.greenAccent : _viability == 'Medium' ? Colors.amberAccent : Colors.orangeAccent;
    return Positioned(
      top: 50, left: 16, right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_phase == _LandPhase.scanning ? 'SCANNING TERRAIN...' : _phase == _LandPhase.analyzing ? 'ANALYZING LAND...' : 'LAND ENERGY POTENTIAL',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                if (_phase == _LandPhase.active)
                  Text('${_areaAcres.toStringAsFixed(1)} acres${_soilType.isNotEmpty ? ' • $_soilType soil' : ''} • $_viability potential',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ])),
              if (_phase == _LandPhase.active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: hColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: hColor.withOpacity(0.4))),
                  child: Text('${_solarCapacityKw.toStringAsFixed(0)} kW', style: TextStyle(color: hColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), border: const Border(top: BorderSide(color: Colors.white10))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Mode toggle
              Row(children: _LandMode.values.map((m) {
                final active = _mode == m;
                final label = m == _LandMode.solar ? '☀️ Solar' : m == _LandMode.agrivoltaic ? '🌿 Agrivoltaic' : '💨 Wind';
                return Expanded(child: GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _mode = m); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(color: active ? Colors.white.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? Colors.white24 : Colors.white10)),
                    child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 12),
              Row(children: [
                _stat('${_areaSqm.toStringAsFixed(0)}', 'm² area', Icons.crop_square),
                _stat('${_solarCapacityKw.toStringAsFixed(0)} kW', 'Capacity', Icons.bolt),
                _stat('₹${(_annualRevenue / 100000).toStringAsFixed(1)}L', '/year', Icons.trending_up),
              ]),
              if (_recommendation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.15))),
                  child: Text(_recommendation, style: const TextStyle(color: Colors.white60, fontSize: 10, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () { HapticFeedback.heavyImpact(); Navigator.pop(context); },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
                  child: const Center(child: Text('VIEW FULL REPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13))),
                ),
              ),
            ]),
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutExpo, duration: 700.ms),
    );
  }

  Widget _stat(String v, String l, IconData i) => Expanded(child: Column(children: [
    Icon(i, color: Colors.white38, size: 16), const SizedBox(height: 4),
    Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    Text(l, style: const TextStyle(color: Colors.white38, fontSize: 10)),
  ]));
}

// ─── PAINTERS ─────────────────────────────────────────────────

class _LandScanPainter extends CustomPainter {
  final double progress;
  _LandScanPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
      ..shader = LinearGradient(colors: [Colors.transparent, Colors.greenAccent.withOpacity(0.4), Colors.transparent]).createShader(Rect.fromLTWH(0, y - 2, size.width, 4))..strokeWidth = 2);
    const l = 25.0;
    final p = Paint()..color = Colors.greenAccent.withOpacity(0.25)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
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
  bool shouldRepaint(_LandScanPainter old) => old.progress != progress;
}

/// Zone-based potential overlay with ground-plane perspective
class _LandZonePainter extends CustomPainter {
  final double pulse, shimmer;
  final _LandMode mode;
  _LandZonePainter({required this.pulse, required this.shimmer, required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    // Ground plane — mapped to lower half where actual land is
    final topY = size.height * 0.50;
    final bottomY = size.height * 0.82;
    final topLeftX = size.width * 0.08;
    final topRightX = size.width * 0.92;
    final botLeftX = -size.width * 0.05;
    final botRightX = size.width * 1.05;

    Offset leftAt(double t) => Offset(topLeftX + (botLeftX - topLeftX) * t, topY + (bottomY - topY) * t);
    Offset rightAt(double t) => Offset(topRightX + (botRightX - topRightX) * t, topY + (bottomY - topY) * t);

    final groundPath = Path()
      ..moveTo(leftAt(0).dx, leftAt(0).dy)..lineTo(rightAt(0).dx, rightAt(0).dy)
      ..lineTo(rightAt(1).dx, rightAt(1).dy)..lineTo(leftAt(1).dx, leftAt(1).dy)..close();

    canvas.save();
    canvas.clipPath(groundPath);

    // Mode-specific colors
    Color primary, secondary;
    switch (mode) {
      case _LandMode.solar: primary = Colors.amber; secondary = Colors.greenAccent; break;
      case _LandMode.agrivoltaic: primary = Colors.lightGreenAccent; secondary = Colors.green; break;
      case _LandMode.wind: primary = Colors.cyanAccent; secondary = Colors.lightBlueAccent; break;
    }

    // 4×3 zone grid
    final rng = math.Random(mode.index * 7 + 13);
    const rows = 4, cols = 3;
    final potentials = List.generate(rows * cols, (i) => 0.3 + rng.nextDouble() * 0.7);
    potentials[rows * cols - 2] = 0.93;
    potentials[rows * cols ~/ 2] = 0.88;
    potentials[1] = 0.85;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        double tTop = row / rows, tBot = (row + 1) / rows;
        double fLeft = col / cols, fRight = (col + 1) / cols;
        final lt = leftAt(tTop), rt = rightAt(tTop), lb = leftAt(tBot), rb = rightAt(tBot);
        double tw = rt.dx - lt.dx, bw = rb.dx - lb.dx;

        final zp = Path()
          ..moveTo(lt.dx + tw * fLeft, lt.dy)..lineTo(lt.dx + tw * fRight, lt.dy)
          ..lineTo(lb.dx + bw * fRight, lb.dy)..lineTo(lb.dx + bw * fLeft, lb.dy)..close();

        double pot = potentials[row * cols + col];
        double op = 0.04 + pot * 0.10 + pulse * 0.02 * pot;
        Color zc = Color.lerp(Colors.red.withOpacity(0.3), secondary, pot)!;

        canvas.drawPath(zp, Paint()..color = zc.withOpacity(op));
        canvas.drawPath(zp, Paint()..color = Colors.white.withOpacity(0.05 + pot * 0.04)..style = PaintingStyle.stroke..strokeWidth = 0.4);

        if (pot > 0.80) {
          final center = zp.getBounds().center;
          final label = pot > 0.88 ? 'HIGH' : 'GOOD';
          _label(canvas, center, label, pot > 0.88 ? secondary : primary, 9);
        }
      }
    }

    // Shimmer sweep across ground
    final sweepT = shimmer;
    final sweepL = leftAt(sweepT);
    final sweepR = rightAt(sweepT);
    canvas.drawLine(sweepL, sweepR, Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 3);

    canvas.restore();

    // Corner survey pins
    final corners = [leftAt(0), rightAt(0), rightAt(1), leftAt(1)];
    for (final c in corners) {
      if (c.dx > -10 && c.dx < size.width + 10) {
        canvas.drawCircle(c, 3, Paint()..color = Colors.white.withOpacity(0.25));
        canvas.drawCircle(c, 1.5, Paint()..color = secondary.withOpacity(0.6));
      }
    }
  }

  void _label(Canvas canvas, Offset pos, String text, Color c, double fs) {
    final tp = TextPainter(text: TextSpan(text: text, style: TextStyle(color: c, fontSize: fs, fontWeight: FontWeight.bold, letterSpacing: 0.8)), textDirection: TextDirection.ltr)..layout();
    final bg = RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: tp.width + 14, height: tp.height + 8), const Radius.circular(5));
    canvas.drawRRect(bg, Paint()..color = Colors.black.withOpacity(0.45));
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_LandZonePainter old) => old.pulse != pulse || old.shimmer != shimmer || old.mode != mode;
}
