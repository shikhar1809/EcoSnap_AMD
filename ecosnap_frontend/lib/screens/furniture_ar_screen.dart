import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlacedItem {
  final String name;
  final IconData icon;
  final String? image;
  final String save;
  Offset position;
  double scale;
  double rotation;
  double tilt;

  PlacedItem({
    required this.name,
    required this.icon,
    this.image,
    required this.save,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.tilt = 0.0,
  });
}

class FurnitureARScreen extends StatefulWidget {
  final Uint8List? imageBytes;

  const FurnitureARScreen({super.key, this.imageBytes});

  @override
  State<FurnitureARScreen> createState() => _FurnitureARScreenState();
}

class _FurnitureARScreenState extends State<FurnitureARScreen> {
  final List<Map<String, dynamic>> _catalog = [
    {"name": "Eco Sofa", "icon": Icons.weekend, "image": "assets/images/sofa_ar.png", "save": "₹12,000", "co2": "180kg"},
    {"name": "Recycled Table", "icon": Icons.table_restaurant, "image": "assets/images/table_ar.png", "save": "₹5,500", "co2": "85kg"},
    {"name": "Solar Lamp", "icon": Icons.light, "image": "assets/images/lamp_ar.png", "save": "₹2,000", "co2": "30kg"},
    {"name": "Smart AC", "icon": Icons.ac_unit, "image": "assets/images/ac_ar.png", "save": "₹15,000", "co2": "250kg"},
    {"name": "Bamboo Armchair", "icon": Icons.chair, "save": "₹8,000", "co2": "120kg"},
  ];
  
  final List<PlacedItem> _placedItems = [];
  int? _selectedPlacedIndex;
  
  // For interaction
  Offset? _startingFocalPoint;
  Offset? _startingItemPosition;
  double? _startingScale;
  double? _startingRotation;

  // IoT Smart Plug Mode (P2)
  bool _isIoTMode = false;
  final List<Map<String, dynamic>> _iotDevices = [
    {"id": "tv_1", "name": "TV & Console", "power": "45W Standby", "position": const Offset(150, 400), "isKilled": false},
    {"id": "ac_1", "name": "Old AC Unit", "power": "1200W Active", "position": const Offset(100, 150), "isKilled": false},
    {"id": "lamp_1", "name": "Halogen Lamp", "power": "60W Active", "position": const Offset(250, 250), "isKilled": false},
  ];

  void _addFromCatalog(Map<String, dynamic> item) {
    setState(() {
      HapticFeedback.lightImpact();
      _placedItems.add(
        PlacedItem(
          name: item['name'],
          icon: item['icon'],
          image: item['image'],
          save: item['save'],
          position: const Offset(150, 300), // Default center-ish
        ),
      );
      _selectedPlacedIndex = _placedItems.length - 1;
    });
  }

  int get _totalSavingsInt {
    int total = 0;
    for (var item in _placedItems) {
      String saveStr = item.save.replaceAll(RegExp(r'[^0-9]'), '');
      total += int.tryParse(saveStr) ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Background (Scanned Image or Dark Fallback)
          Positioned.fill(
            child: widget.imageBytes != null
                ? Image.memory(widget.imageBytes!, fit: BoxFit.cover)
                : const Opacity(
                    opacity: 0.2,
                    child: Icon(Icons.home_work_outlined, size: 200, color: Colors.white),
                  ),
          ),
          
          // Slight gradient at top/bottom for readable text
          Positioned.fill(
            child: Column(
              children: [
                Container(height: 120, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent]))),
                const Spacer(),
                Container(height: 180, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent]))),
              ],
            ),
          ),

          // 2. Placed AR Items
          ..._placedItems.asMap().entries.map((entry) {
            int idx = entry.key;
            PlacedItem pi = entry.value;
            bool isSelected = idx == _selectedPlacedIndex;
            
            return Positioned(
              left: pi.position.dx,
              top: pi.position.dy,
              child: GestureDetector(
                onScaleStart: (details) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedPlacedIndex = idx;
                    _startingFocalPoint = details.focalPoint;
                    _startingItemPosition = pi.position;
                    _startingScale = pi.scale;
                    _startingRotation = pi.rotation;
                  });
                },
                onScaleUpdate: (details) {
                  if (_startingFocalPoint == null || _startingItemPosition == null) return;
                  setState(() {
                    pi.position = _startingItemPosition! + (details.focalPoint - _startingFocalPoint!);
                    pi.scale = (_startingScale! * details.scale).clamp(0.4, 4.0);
                  });
                },
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective depth
                    ..rotateX(pi.tilt)
                    ..rotateZ(pi.rotation),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: pi.scale,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (pi.image != null)
                          // Realistic PNG Representation
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Floor drop shadow matching rotation and scale
                              Container(
                                width: 160,
                                height: 40,
                                margin: const EdgeInsets.only(top: 140),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isSelected ? 0.7 : 0.4),
                                      blurRadius: isSelected ? 25 : 15,
                                      spreadRadius: isSelected ? 8 : 2,
                                    )
                                  ]
                                ),
                              ),
                              if (isSelected) 
                                Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
                                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)]
                                  ),
                                ),
                              Image.asset(pi.image!, width: 200, fit: BoxFit.contain),
                            ],
                          )
                        else
                          // Pseudo-3D Equipment Representation
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? Colors.greenAccent : Colors.white38, 
                                width: isSelected ? 3 : 1
                              ),
                              boxShadow: [
                                // Deep drop shadow to look like it's placed in 3D space
                                BoxShadow(
                                  color: isSelected ? Colors.greenAccent.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                                  blurRadius: isSelected ? 30 : 20,
                                  offset: const Offset(0, 20),
                                  spreadRadius: isSelected ? 4 : 0,
                                ),
                                // Highlight for glass effect
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 4,
                                  offset: const Offset(-2, -2),
                                  spreadRadius: 1,
                                )
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white.withOpacity(0.9), Colors.blueGrey.shade100.withOpacity(0.8)],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Icon(
                                    pi.icon,
                                    size: 60,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                // 3D reflection highlight
                                Positioned(
                                  top: 4, left: 10, right: 10,
                                  child: Container(
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        // Label that always stays upright (we undo the rotation/tilt for the label, but it moves with the item)
                        if (isSelected)
                          Positioned(
                            top: -50,
                            left: -20,
                            right: -20,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..rotateZ(-pi.rotation)
                                ..rotateX(-pi.tilt),
                              alignment: Alignment.center,
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black87.withOpacity(0.8), 
                                    borderRadius: BorderRadius.circular(12), 
                                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
                                    ]
                                  ),
                                  child: Column(
                                    children: [
                                      Text(pi.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      Text("Saves ${pi.save}/yr", style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                                    ],
                                  ),
                                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0),
                                ),
                              ),
                            ),
                          ),
                        if (!isSelected)
                          Positioned(
                            bottom: -25, left: -20, right: -20,
                            child: Transform.rotate(
                              angle: -pi.rotation,
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.black54.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                                      child: Text(pi.name, style: const TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.02, end: 0.02, duration: 2.seconds, curve: Curves.easeInOutSine),
                ).animate().scale(delay: 100.ms, duration: 300.ms, curve: Curves.easeOutBack), // Entering pop animation
              ),
            );
          }),

          // 2.5 IoT Tags Overlay
          if (_isIoTMode)
            ..._buildIoTTags(),

          // 3. Top UI
          Positioned(
            top: 50, left: 16, right: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                        Text(_isIoTMode ? "LIVE IOT VIEW" : "FURNITURE AR", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                      ],
                    ),
                    if (!_isIoTMode && _placedItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.5))
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Projected Savings", style: TextStyle(color: Colors.white54, fontSize: 10)),
                            Text("₹$_totalSavingsInt/yr", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
                  ],
                ),
                const SizedBox(height: 10),
                // Mode Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isIoTMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: !_isIoTMode ? Colors.blueAccent : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                          child: const Text("Design Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isIoTMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: _isIoTMode ? Colors.orangeAccent : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: const [
                              Icon(Icons.wifi_tethering, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text("IoT Mode", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // Tools / Delete / Info Overlay
          if (!_isIoTMode && _selectedPlacedIndex != null && _placedItems.isNotEmpty)
            Positioned(
              left: 20, top: 180,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  setState(() {
                    _placedItems.removeAt(_selectedPlacedIndex!);
                    _selectedPlacedIndex = _placedItems.isNotEmpty ? _placedItems.length - 1 : null;
                  });
                },
                child: const Icon(Icons.delete, color: Colors.white, size: 20),
              ).animate().scale(),
            ),

          if (!_isIoTMode)
            Positioned(
              bottom: 30, left: 16, right: 16,
              child: Column(
                children: [
                  if (_placedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text("Tap an item below to place it in your room", style: TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24, width: 1.5)
                        ),
                        child: _selectedPlacedIndex != null ? _buildAdjustmentPanel() : _buildCatalogPanel(),
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildCatalogPanel() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _catalog.length,
      itemBuilder: (context, index) {
        final item = _catalog[index];
        return GestureDetector(
          onTap: () => _addFromCatalog(item),
          child: Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (item['image'] != null)
                  Image.asset(item['image'], height: 40, fit: BoxFit.contain)
                else
                  Icon(item['icon'], color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(item['name'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
                Text("-${item['co2']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdjustmentPanel() {
    final pi = _placedItems[_selectedPlacedIndex!];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.rotate_right, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text("Spin  ", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: pi.rotation,
                  min: -3.14,
                  max: 3.14,
                  activeColor: Colors.greenAccent,
                  onChanged: (val) {
                    setState(() => pi.rotation = val);
                  }
                )
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedPlacedIndex = null);
                }
              )
            ]
          ),
          Row(
            children: [
              const Icon(Icons.screen_rotation, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text("Tilt  ", style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: pi.tilt,
                  min: -1.0,
                  max: 1.0,
                  activeColor: Colors.amber,
                  onChanged: (val) {
                    setState(() => pi.tilt = val);
                  }
                )
              ),
              const SizedBox(width: 48), // balance space for check icon
            ]
          ),
        ]
      )
    );
  }

  List<Widget> _buildIoTTags() {
    return _iotDevices.map((device) {
      Offset pos = device['position'] as Offset;
      bool killed = device['isKilled'] as bool;
      String pwr = device['power'] as String;
      
      return Positioned(
        left: pos.dx, top: pos.dy,
        child: Column(
          children: [
            // AR Tag
            Container(
              width: 130,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: killed ? Colors.green.withOpacity(0.8) : Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: killed ? Colors.greenAccent : Colors.redAccent, width: 2),
                boxShadow: [BoxShadow(color: killed ? Colors.greenAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text(device['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(killed ? Icons.power_off : Icons.bolt, color: killed ? Colors.white : Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(killed ? "0W (Offline)" : pwr, style: TextStyle(color: killed ? Colors.white : Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity, height: 26,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => device['isKilled'] = !killed);
                        if (!killed) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signal sent to Smart Plug: POWER OFF 🔌")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: killed ? Colors.white24 : Colors.redAccent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(killed ? "TURN ON" : "KILL POWER", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: -0.05, end: 0.05, duration: 2.seconds),
            // Connector line to "device"
            Container(
              width: 3, 
              height: 40, 
              decoration: BoxDecoration(
                color: killed ? Colors.greenAccent : Colors.redAccent,
                boxShadow: [BoxShadow(color: killed ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5), blurRadius: 6)]
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.seconds, color: Colors.white),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: killed ? Colors.greenAccent : Colors.redAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: killed ? Colors.greenAccent : Colors.redAccent, blurRadius: 8)])),
          ],
        ),
      );
    }).toList();
  }
}
