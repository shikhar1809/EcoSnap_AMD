import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class SolarARScreen extends StatefulWidget {
  final Map<String, dynamic>? solarData;
  
  const SolarARScreen({super.key, this.solarData});

  @override
  State<SolarARScreen> createState() => _SolarARScreenState();
}

class _SolarARScreenState extends State<SolarARScreen> with SingleTickerProviderStateMixin {
  // Panel placement
  final List<Offset> _panelPositions = [];
  int _panelCount = 0;
  double _totalKw = 0.0;
  double _totalCost = 0.0;
  
  // Solar panel specs (standard 330W panel)
  static const double panelWattage = 0.33; // kW
  static const double panelCost = 15000; // ₹ per panel
  static const double panelWidth = 60.0; // UI size
  static const double panelHeight = 100.0;
  
  // Simulation
  late AnimationController _sunController;
  bool _showShadows = true;
  int _timeOfDay = 12; // 12 = noon
  
  // Solar data from backend
  late double _maxKw;
  late int _recommendedPanels;
  
  @override
  void initState() {
    super.initState();
    
    // Get solar data from backend or use defaults
    final solarViability = widget.solarData?['solar_viability'] ?? {};
    String potentialKw = solarViability['potential_kw'] ?? '2.5kW';
    _maxKw = double.parse(potentialKw.replaceAll('kW', ''));
    _recommendedPanels = (_maxKw / panelWattage).ceil();
    
    // Initialize with recommended configuration
    _initializePanels();
    
    // Sun animation
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }
  
  void _initializePanels() {
    // Create 2x4 grid layout (8 panels for 2.5kW)
    _panelPositions.clear();
    int rows = 2;
    int cols = math.min(4, (_recommendedPanels / rows).ceil());
    
    double startX = 100;
    double startY = 150;
    double spacing = 10;
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (_panelCount >= _recommendedPanels) break;
        _panelPositions.add(Offset(
          startX + col * (panelWidth + spacing),
          startY + row * (panelHeight + spacing),
        ));
        _panelCount++;
      }
    }
    
    _updateCalculations();
  }
  
  void _updateCalculations() {
    setState(() {
      _totalKw = _panelCount * panelWattage;
      _totalCost = _panelCount * panelCost;
    });
  }
  
  void _addPanel(Offset position) {
    if (_totalKw >= _maxKw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum roof capacity reached!'))
      );
      return;
    }
    
    setState(() {
      _panelPositions.add(position);
      _panelCount++;
      _updateCalculations();
    });
  }
  
  void _removePanel(int index) {
    setState(() {
      _panelPositions.removeAt(index);
      _panelCount--;
      _updateCalculations();
    });
  }

  @override
  void dispose() {
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate sun position based on time
    double sunAngle = (_timeOfDay - 6) / 12 * math.pi; // 6am to 6pm
    double sunX = MediaQuery.of(context).size.width / 2 + math.cos(sunAngle) * 150;
    double sunY = 100 - math.sin(sunAngle) * 80;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Sky gradient (changes with time of day)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getSkyColors(),
                ),
              ),
            ),
          ),
          
          // Roof backdrop (mock)
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(
                painter: RoofPainter(),
              ),
            ),
          ),
          
          // Sun
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: sunX,
            top: sunY,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.wb_sunny, color: Colors.white, size: 30),
            ),
          ),
          
          // Solar Panels
          ..._panelPositions.asMap().entries.map((entry) {
            int index = entry.key;
            Offset pos = entry.value;
            
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                onTap: () => _removePanel(index),
                onPanUpdate: (details) {
                  setState(() {
                    _panelPositions[index] = Offset(
                      (_panelPositions[index].dx + details.delta.dx).clamp(0, MediaQuery.of(context).size.width - panelWidth),
                      (_panelPositions[index].dy + details.delta.dy).clamp(100, MediaQuery.of(context).size.height - 300),
                    );
                  });
                },
                child: _buildSolarPanel(index, sunAngle),
              ),
            );
          }),
          
          // Add panel button (tap anywhere on roof)
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) {
                if (details.localPosition.dy > 100 && details.localPosition.dy < MediaQuery.of(context).size.height - 250) {
                  _addPanel(details.localPosition);
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Header
          Positioned(
            top: 50, left: 20, right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "SOLAR AR PREVIEW",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_totalKw.toStringAsFixed(1)} kW",
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // Stats panel
          Positioned(
            top: 110, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem("Panels", "$_panelCount", Icons.solar_power),
                      _statItem("Cost", "₹${(_totalCost / 1000).toStringAsFixed(0)}K", Icons.currency_rupee),
                      _statItem("Savings", "₹${(_totalKw * 18000).toStringAsFixed(0)}/yr", Icons.savings),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _totalKw / _maxKw,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      _totalKw >= _maxKw ? Colors.red : Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${(_totalKw / _maxKw * 100).toStringAsFixed(0)}% of roof capacity used",
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          
          // Controls
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Column(
              children: [
                // Time of day slider
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wb_twilight, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          const Text("Time of Day", style: TextStyle(color: Colors.white, fontSize: 12)),
                          const Spacer(),
                          Text(
                            "${_timeOfDay}:00",
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: _timeOfDay.toDouble(),
                        min: 6,
                        max: 18,
                        divisions: 12,
                        activeColor: Colors.amber,
                        onChanged: (value) {
                          setState(() {
                            _timeOfDay = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _initializePanels,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Show quote screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Get quotes for $_panelCount panels (${_totalKw.toStringAsFixed(1)}kW system)"),
                              action: SnackBarAction(label: "OK", onPressed: () {}),
                            ),
                          );
                        },
                        icon: const Icon(Icons.request_quote),
                        label: const Text("Get Quote"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tap to add panels • Drag to reposition • Tap panel to remove",
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSolarPanel(int index, double sunAngle) {
    // Calculate shadow based on sun position
    double shadowOpacity = _showShadows ? (0.3 * math.sin(sunAngle)).clamp(0.0, 0.3) : 0.0;
    
    return Container(
      width: panelWidth,
      height: panelHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a237e),
            const Color(0xFF0d47a1),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: 10,
            offset: Offset(math.cos(sunAngle) * 5, math.sin(sunAngle) * 5),
          ),
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Grid pattern
          CustomPaint(
            painter: SolarCellPainter(),
            size: Size(panelWidth, panelHeight),
          ),
          // Power indicator
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${(panelWattage * 1000).toInt()}W",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
      .fadeIn(duration: 300.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
  
  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
  
  List<Color> _getSkyColors() {
    // Morning (6-10): Orange tint
    // Noon (10-14): Bright blue
    // Evening (14-18): Purple/orange
    if (_timeOfDay < 10) {
      return [const Color(0xFF1a237e), const Color(0xFFff6f00)];
    } else if (_timeOfDay < 14) {
      return [const Color(0xFF0d47a1), const Color(0xFF42a5f5)];
    } else {
      return [const Color(0xFF4a148c), const Color(0xFFff6f00)];
    }
  }
}

class SolarCellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw 6x10 grid (60 cells)
    int rows = 10;
    int cols = 6;
    double cellWidth = size.width / cols;
    double cellHeight = size.height / rows;
    
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(i * cellWidth, 0),
        Offset(i * cellWidth, size.height),
        paint,
      );
    }
    
    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellHeight),
        Offset(size.width, i * cellHeight),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoofPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    // Draw simple roof shape
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(size.width / 2, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(path, paint);
    
    // Roof tiles texture
    final tilePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    
    for (double y = size.height * 0.3; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        tilePaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

