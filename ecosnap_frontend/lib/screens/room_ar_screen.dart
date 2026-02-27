import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class RoomARScreen extends StatefulWidget {
  final Map<String, dynamic>? roomData;
  final Uint8List? imageBytes;

  const RoomARScreen({super.key, this.roomData, this.imageBytes});

  @override
  State<RoomARScreen> createState() => _RoomARScreenState();
}

enum _RoomPhase { scanning, analyzing, active }

class _ApplianceNode {
  final String name;
  final double watts;
  final String rating;
  final bool isEfficient;
  final String tip;
  final Offset position;

  _ApplianceNode({required this.name, required this.watts, required this.rating, required this.isEfficient, required this.tip, required this.position});
}

class _RoomARScreenState extends State<RoomARScreen> with TickerProviderStateMixin {
  _RoomPhase _phase = _RoomPhase.scanning;

  int _efficiencyScore = 72;
  double _totalWatts = 0;
  double _monthlyCost = 0;
  String _recommendation = '';
  List<_ApplianceNode> _nodes = [];
  List<String> _detectedObjects = [];
  int? _selectedIndex;

  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _parseData();
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startScan();
  }

  void _parseData() {
    final d = widget.roomData ?? {};
    _efficiencyScore = (d['efficiency_score'] as num?)?.toInt() ?? 72;
    _recommendation = (d['recommendation'] ?? d['recommendations'] ?? '').toString();

    final objects = d['detected_objects'] as List? ?? [];
    _detectedObjects = objects.map<String>((o) => (o is Map ? o['name'] : o).toString()).toList();

    final rawAppliances = d['appliances'] as List? ?? d['detected_appliances'] as List? ?? [];
    final rng = math.Random(7);

    if (rawAppliances.isNotEmpty) {
      _nodes = rawAppliances.asMap().entries.map<_ApplianceNode>((entry) {
        final i = entry.key;
        final a = entry.value as Map;
        final name = (a['name'] ?? a['appliance'] ?? 'Device ${i + 1}').toString();
        final watts = (a['wattage'] as num?)?.toDouble() ?? (a['power_watts'] as num?)?.toDouble() ?? 100;
        final rating = (a['efficiency_rating'] ?? a['star_rating'] ?? '3★').toString();
        final isGood = watts < 200 || rating.contains('4') || rating.contains('5');
        final tip = (a['tip'] ?? a['recommendation'] ?? (isGood ? 'Efficient ✓' : 'Consider upgrading')).toString();
        return _ApplianceNode(
          name: name, watts: watts, rating: rating, isEfficient: isGood, tip: tip,
          position: Offset(0.12 + rng.nextDouble() * 0.76, 0.18 + rng.nextDouble() * 0.50),
        );
      }).toList();
    } else {
      // Map detected YOLO objects to appliance-like nodes
      final applianceMap = {
        'tv': _AppDef('TV', 120, '4★', true, 'Efficient standby mode'),
        'monitor': _AppDef('Monitor', 80, '4★', true, 'Use power strip'),
        'laptop': _AppDef('Laptop', 65, '5★', true, 'Good efficiency'),
        'refrigerator': _AppDef('Fridge', 350, '3★', false, 'Check door seal'),
        'microwave': _AppDef('Microwave', 1200, '3★', false, 'Use for short bursts'),
        'oven': _AppDef('Oven', 2000, '2★', false, 'High consumer'),
        'cell phone': _AppDef('Charger', 15, '5★', true, 'Low draw'),
        'clock': _AppDef('Clock', 5, '5★', true, 'Minimal use'),
        'chair': null, 'couch': null, 'bed': null, 'dining table': null, 'person': null,
      };

      for (int i = 0; i < _detectedObjects.length && _nodes.length < 6; i++) {
        final name = _detectedObjects[i].toLowerCase();
        final def = applianceMap[name];
        if (def != null) {
          _nodes.add(_ApplianceNode(
            name: def.name, watts: def.watts, rating: def.rating, isEfficient: def.isGood, tip: def.tip,
            position: Offset(0.15 + rng.nextDouble() * 0.70, 0.20 + rng.nextDouble() * 0.45),
          ));
        }
      }

      if (_nodes.isEmpty) {
        _nodes = [
          _ApplianceNode(name: 'AC', watts: 1500, rating: '3★', isEfficient: false, tip: 'Set to 24°C to save 15%', position: const Offset(0.72, 0.25)),
          _ApplianceNode(name: 'Lights', watts: 60, rating: '5★', isEfficient: true, tip: 'LED — efficient', position: const Offset(0.50, 0.15)),
          _ApplianceNode(name: 'TV', watts: 120, rating: '4★', isEfficient: true, tip: 'Use auto-brightness', position: const Offset(0.28, 0.42)),
          _ApplianceNode(name: 'Fridge', watts: 350, rating: '3★', isEfficient: false, tip: 'Upgrade to 5-star model', position: const Offset(0.18, 0.55)),
          _ApplianceNode(name: 'Fan', watts: 75, rating: '5★', isEfficient: true, tip: 'BLDC motor — efficient', position: const Offset(0.68, 0.48)),
        ];
      }
    }

    _totalWatts = _nodes.fold(0, (sum, n) => sum + n.watts);
    _monthlyCost = _totalWatts * 0.72 * 30 / 1000;
  }

  void _startScan() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _phase = _RoomPhase.analyzing);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _phase = _RoomPhase.active);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() { _scanCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.imageBytes != null
                ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF0a0f1a)),
          ),
          if (_phase == _RoomPhase.scanning)
            Positioned.fill(child: AnimatedBuilder(animation: _scanCtrl, builder: (_, __) => CustomPaint(painter: _RoomScanPainter(progress: _scanCtrl.value)))),
          if (_phase == _RoomPhase.analyzing)
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3)).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 400.ms).fadeOut(duration: 400.ms)),

          // Appliance markers
          if (_phase == _RoomPhase.active)
            ..._nodes.asMap().entries.map((entry) {
              final i = entry.key;
              final node = entry.value;
              final x = node.position.dx * sw;
              final y = node.position.dy * sh;
              final sel = _selectedIndex == i;
              final color = node.isEfficient ? Colors.greenAccent : Colors.orangeAccent;

              return Positioned(
                left: x - 20, top: y - 20,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = sel ? null : i),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) {
                      final rs = 40.0 + _pulseCtrl.value * 4;
                      return Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: rs, height: rs,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.4 + _pulseCtrl.value * 0.2), width: 1.5),
                            color: color.withOpacity(0.06),
                          ),
                          child: Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color))),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.2))),
                          child: Text('${node.name} • ${node.watts.toInt()}W', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                        if (sel) Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          constraints: const BoxConstraints(maxWidth: 160),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Rating: ${node.rating}', style: const TextStyle(color: Colors.white60, fontSize: 9)),
                            const SizedBox(height: 2),
                            Text(node.tip, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                          ]),
                        ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2),
                      ]);
                    },
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: (80 * i).ms).scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1));
            }),

          _buildHeader(),
          if (_phase == _RoomPhase.active) _buildBottom(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final scoreColor = _efficiencyScore > 75 ? Colors.greenAccent : _efficiencyScore > 50 ? Colors.amberAccent : Colors.orangeAccent;
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
                Text(_phase == _RoomPhase.scanning ? 'SCANNING ROOM...' : _phase == _RoomPhase.analyzing ? 'DETECTING APPLIANCES...' : 'ROOM ENERGY AUDIT',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                if (_phase == _RoomPhase.active)
                  Text('${_nodes.length} appliances • ${_totalWatts.toInt()}W total draw', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ])),
              if (_phase == _RoomPhase.active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: scoreColor.withOpacity(0.4))),
                  child: Text('$_efficiencyScore/100', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
                _stat('${_totalWatts.toInt()}', 'Watts', Icons.electric_bolt),
                _stat('₹${_monthlyCost.toStringAsFixed(0)}', '/month', Icons.currency_rupee),
                _stat('$_efficiencyScore', 'Score', Icons.speed),
              ]),
              if (_recommendation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purpleAccent.withOpacity(0.15))),
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

class _AppDef {
  final String name;
  final double watts;
  final String rating;
  final bool isGood;
  final String tip;
  _AppDef(this.name, this.watts, this.rating, this.isGood, this.tip);
}

// ─── PAINTER ─────────────────────────────────────────────────

class _RoomScanPainter extends CustomPainter {
  final double progress;
  _RoomScanPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()
      ..shader = LinearGradient(colors: [Colors.transparent, Colors.purpleAccent.withOpacity(0.4), Colors.transparent]).createShader(Rect.fromLTWH(0, y - 2, size.width, 4))..strokeWidth = 2);
    const l = 25.0;
    final p = Paint()..color = Colors.purpleAccent.withOpacity(0.25)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
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
  bool shouldRepaint(_RoomScanPainter old) => old.progress != progress;
}
