import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class WindARScreen extends StatefulWidget {
  final Map<String, dynamic>? windData;
  final Uint8List? imageBytes;

  const WindARScreen({super.key, this.windData, this.imageBytes});

  @override
  State<WindARScreen> createState() => _WindARScreenState();
}

enum _WindPhase { scanning, analyzing, active }

class _WindARScreenState extends State<WindARScreen> with TickerProviderStateMixin {
  _WindPhase _phase = _WindPhase.scanning;

  double _avgWindSpeed = 6.2;
  double _capacityFactor = 0.28;
  double _annualGenKwh = 2000;
  double _paybackYears = 0;
  double _annualSavings = 0;
  String _viability = 'Moderate';
  String _recommendation = '';
  String _windDirection = 'NW';
  double _windDirDeg = 315;
  String _roughnessClass = '';
  String _flowQuality = '';
  List<String> _detectedObjects = [];

  late AnimationController _scanCtrl;
  late AnimationController _flowCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _parseData();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _flowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _startScan();
  }

  void _parseData() {
    final d = widget.windData ?? {};
    final potential = d['wind_potential'] ?? {};
    final financial = d['financial_analysis'] as Map? ?? {};
    final site = d['site_analysis'] ?? {};
    final locWind = (d['location_data'] as Map?)?['wind'] as Map? ?? {};
    final windAnalysis = d['wind_analysis'] as Map? ?? {};

    final objects = d['detected_objects'] as List? ?? [];
    _detectedObjects = objects.map<String>((o) => (o is Map ? o['name'] : o).toString()).toList();

    _avgWindSpeed = (locWind['wind_speed_ms'] as num?)?.toDouble()
        ?? (site['average_wind_speed_ms'] as num?)?.toDouble()
        ?? (potential['avg_wind_speed'] as num?)?.toDouble() ?? 6.2;
    _windDirDeg = (locWind['wind_direction_deg'] as num?)?.toDouble() ?? 315;
    _windDirection = _degToCardinal(_windDirDeg);
    _capacityFactor = (potential['capacity_factor'] as num?)?.toDouble() ?? 0.28;
    _annualGenKwh = (potential['estimated_annual_generation_kwh'] as num?)?.toDouble() ?? 2000;
    _viability = potential['viability'] ?? locWind['suitability'] ?? windAnalysis['suitability'] ?? 'Moderate';
    _paybackYears = (financial['payback_period_years'] as num?)?.toDouble() ?? 0;
    _roughnessClass = (site['roughness_class'] ?? '').toString();
    _flowQuality = (site['flow_quality'] ?? '').toString();
    _recommendation = (d['recommendation'] ?? '').toString();

    final sysCost = (financial['system_cost_estimate_inr'] as num?)?.toDouble() ?? 0;
    _annualSavings = _paybackYears > 0 && sysCost > 0 ? sysCost / _paybackYears : _annualGenKwh * 8.5;
  }

  String _degToCardinal(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22.5) % 360 / 45).floor()];
  }

  void _startScan() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _phase = _WindPhase.analyzing);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _phase = _WindPhase.active);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() { _scanCtrl.dispose(); _flowCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

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
          if (_phase == _WindPhase.scanning)
            Positioned.fill(child: AnimatedBuilder(
              animation: _scanCtrl,
              builder: (_, __) => CustomPaint(painter: _ScanPainter(progress: _scanCtrl.value)),
            )),
          if (_phase == _WindPhase.analyzing)
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))
              .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 400.ms).fadeOut(duration: 400.ms)),
          if (_phase == _WindPhase.active)
            Positioned.fill(child: AnimatedBuilder(
              animation: Listenable.merge([_flowCtrl, _pulseCtrl]),
              builder: (_, __) => CustomPaint(
                painter: _WindFlowPainter(
                  flow: _flowCtrl.value, pulse: _pulseCtrl.value,
                  windSpeed: _avgWindSpeed, windDirDeg: _windDirDeg,
                ),
              ),
            ).animate().fadeIn(duration: 800.ms)),
          _buildHeader(),
          if (_phase == _WindPhase.active && _detectedObjects.isNotEmpty)
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
          if (_phase == _WindPhase.active) _buildBottom(),
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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _phase == _WindPhase.scanning ? 'SCANNING TERRAIN...' : _phase == _WindPhase.analyzing ? 'ANALYZING WIND...' : 'WIND POTENTIAL',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                ),
                if (_phase == _WindPhase.active)
                  Text('$_windDirection wind • ${_avgWindSpeed.toStringAsFixed(1)} m/s${_flowQuality.isNotEmpty ? ' • $_flowQuality flow' : ''}',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ])),
              if (_phase == _WindPhase.active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (_viability == 'High' ? Colors.greenAccent : Colors.cyanAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (_viability == 'High' ? Colors.greenAccent : Colors.cyanAccent).withOpacity(0.4)),
                  ),
                  child: Text(_viability, style: TextStyle(color: _viability == 'High' ? Colors.greenAccent : Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), border: const Border(top: BorderSide(color: Colors.white10))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                _stat('${_avgWindSpeed.toStringAsFixed(1)}', 'm/s avg', Icons.air),
                _stat('${(_annualGenKwh / 1000).toStringAsFixed(1)}', 'MWh/yr', Icons.bolt),
                _stat('₹${(_annualSavings / 1000).toStringAsFixed(0)}K', '/year', Icons.savings),
              ]),
              if (_recommendation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.cyanAccent.withOpacity(0.15))),
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

// ─── PAINTERS ──────────────────────────────────────────────────

class _ScanPainter extends CustomPainter {
  final double progress;
  _ScanPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.cyanAccent.withOpacity(0.4), Colors.transparent])
        .createShader(Rect.fromLTWH(x - 2, 0, 4, size.height))..strokeWidth = 2);
    // Brackets
    const l = 25.0;
    final p = Paint()..color = Colors.cyanAccent.withOpacity(0.25)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
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
  bool shouldRepaint(_ScanPainter old) => old.progress != progress;
}

class _WindFlowPainter extends CustomPainter {
  final double flow, pulse, windSpeed, windDirDeg;
  _WindFlowPainter({required this.flow, required this.pulse, required this.windSpeed, required this.windDirDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    // Convert wind direction to a vector (degrees -> radians, meteorological convention)
    final dirRad = (windDirDeg + 180) * math.pi / 180; // +180 because wind "from" direction
    final dx = math.sin(dirRad);
    final dy = -math.cos(dirRad);

    // Flow lines following actual wind direction
    for (int i = 0; i < 30; i++) {
      double baseX = rng.nextDouble() * size.width;
      double baseY = size.height * 0.15 + rng.nextDouble() * size.height * 0.65;
      double len = 30 + rng.nextDouble() * 50 + windSpeed * 3;
      double speed = 0.5 + rng.nextDouble() * 0.5;

      // Animate along wind direction
      double t = (flow * speed * 2) % 1.0;
      double offsetX = baseX + t * size.width * dx * 0.8;
      double offsetY = baseY + t * size.height * dy * 0.4;

      // Wrap around
      offsetX = offsetX % (size.width + len);
      offsetY = offsetY.clamp(0, size.height);

      final startPt = Offset(offsetX, offsetY);
      final endPt = Offset(offsetX + len * dx, offsetY + len * dy);

      // Fade based on vertical position (lighter near horizon)
      double alpha = 0.05 + (1 - (baseY / size.height).clamp(0, 1)) * 0.08;
      final lp = Paint()..color = Colors.white.withOpacity(alpha)..strokeWidth = 0.8..strokeCap = StrokeCap.round;
      canvas.drawLine(startPt, endPt, lp);

      // Arrowhead
      if (len > 40) {
        final arrowLen = 5.0;
        final perpDx = -dy;
        final perpDy = dx;
        canvas.drawLine(endPt, Offset(endPt.dx - arrowLen * dx + arrowLen * 0.4 * perpDx, endPt.dy - arrowLen * dy + arrowLen * 0.4 * perpDy), lp);
        canvas.drawLine(endPt, Offset(endPt.dx - arrowLen * dx - arrowLen * 0.4 * perpDx, endPt.dy - arrowLen * dy - arrowLen * 0.4 * perpDy), lp);
      }
    }

    // Optimal zone circles — positioned in open areas
    final zones = [
      _ZoneInfo(Offset(size.width * 0.3, size.height * 0.45), 'ZONE A', true),
      _ZoneInfo(Offset(size.width * 0.7, size.height * 0.5), 'ZONE B', false),
    ];

    for (final z in zones) {
      final r = 30.0 + pulse * 8;
      final c = z.optimal ? Colors.greenAccent : Colors.cyanAccent;

      canvas.drawCircle(z.pos, r, Paint()..color = c.withOpacity(0.08 + pulse * 0.04)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(z.pos, r * 0.5, Paint()..color = c.withOpacity(0.04 + pulse * 0.02));
      canvas.drawCircle(z.pos, 3, Paint()..color = c.withOpacity(0.5));

      final label = '${z.name} — ${z.optimal ? "OPTIMAL" : "GOOD"}';
      final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(color: c.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
      final bg = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(z.pos.dx, z.pos.dy - r - 12), width: tp.width + 12, height: tp.height + 6), const Radius.circular(4));
      canvas.drawRRect(bg, Paint()..color = Colors.black.withOpacity(0.45));
      tp.paint(canvas, Offset(z.pos.dx - tp.width / 2, z.pos.dy - r - 12 - tp.height / 2));
    }

    // Compass rose (small, top-left area)
    _drawCompass(canvas, Offset(size.width * 0.12, size.height * 0.82), windDirDeg, windSpeed);
  }

  void _drawCompass(Canvas canvas, Offset center, double deg, double speed) {
    const r = 22.0;
    // Circle bg
    canvas.drawCircle(center, r, Paint()..color = Colors.black.withOpacity(0.4));
    canvas.drawCircle(center, r, Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1);
    // N marker
    final np = TextPainter(text: TextSpan(text: 'N', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 8, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    np.paint(canvas, Offset(center.dx - np.width / 2, center.dy - r - 2 - np.height));
    // Arrow showing wind direction
    final arrowRad = (deg + 180) * math.pi / 180;
    final arrowEnd = Offset(center.dx + math.sin(arrowRad) * (r - 5), center.dy - math.cos(arrowRad) * (r - 5));
    canvas.drawLine(center, arrowEnd, Paint()..color = Colors.cyanAccent.withOpacity(0.7)..strokeWidth = 2..strokeCap = StrokeCap.round);
    canvas.drawCircle(center, 2, Paint()..color = Colors.cyanAccent);
    // Speed label
    final sp = TextPainter(text: TextSpan(text: '${speed.toStringAsFixed(1)}', style: TextStyle(color: Colors.cyanAccent.withOpacity(0.6), fontSize: 7, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout();
    sp.paint(canvas, Offset(center.dx - sp.width / 2, center.dy + r + 3));
  }

  @override
  bool shouldRepaint(_WindFlowPainter old) => old.flow != flow || old.pulse != pulse;
}

class _ZoneInfo {
  final Offset pos;
  final String name;
  final bool optimal;
  _ZoneInfo(this.pos, this.name, this.optimal);
}
