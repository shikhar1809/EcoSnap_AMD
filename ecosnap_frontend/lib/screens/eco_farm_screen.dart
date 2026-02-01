import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import 'dart:math' as math;

class EcoFarmScreen extends StatefulWidget {
  const EcoFarmScreen({super.key});

  @override
  State<EcoFarmScreen> createState() => _EcoFarmScreenState();
}

class _EcoFarmScreenState extends State<EcoFarmScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final String _demoUserId = "user_123"; 

  double _carbonSaved = 0.0;
  int _points = 150; // Starter points to begin planting
  bool _isLoading = true;

  // 3D Rotation State
  double _rotationX = 0.6; // Initial "Isometric" view (tilted back)
  double _rotationY = 0.0;

  late AnimationController _bgController;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Rotate Only (No Panning)
      _rotationY -= details.delta.dx * 0.01; 
      _rotationX += details.delta.dy * 0.01; 
      
      // No clamp - Full 3D Control
      // _rotationX = _rotationX.clamp(0.0, 0.9); 
    });
  }

  void _resetView() {
    setState(() {
       _rotationX = 1.0;
       _rotationY = 0.0;
    });
  }

  // PvZ Style Plants (Restricted to 3 for Demo)
  final List<Map<String, dynamic>> _plants = [
    {'name': 'Sun Bloom', 'icon': Icons.wb_sunny, 'image': 'assets/images/sunflower.png', 'unlockAt': 0, 'desc': 'Generates optimism.', 'quantity': 5, 'cost': 50},
    {'name': 'Pea Shooter', 'icon': Icons.eco, 'image': 'assets/images/peashooter.png', 'unlockAt': 0, 'desc': 'Shoots down emissions.', 'quantity': 5, 'cost': 50},
    {'name': 'Carbon Nut', 'icon': Icons.shield, 'image': 'assets/images/carbon_nut.png', 'unlockAt': 0, 'desc': 'Blocks pollution.', 'quantity': 5, 'cost': 50},
  ];

  void _decrementSeed(String plantName) {
    setState(() {
      final idx = _plants.indexWhere((p) => p['name'] == plantName);
      if (idx != -1 && (_plants[idx]['quantity'] ?? 5) > 0) {
        _plants[idx]['quantity'] = (_plants[idx]['quantity'] ?? 5) - 1;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: 20.seconds)..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final status = await _apiService.getUserStatus(_demoUserId);
    if (mounted) {
      setState(() {
        _carbonSaved = (status['carbon_saved'] ?? 0.0).toDouble();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Game Logic
    Map<String, dynamic>? nextPlant;
    for (var plant in _plants) {
      if (_carbonSaved < (plant['unlockAt'] as int)) {
        nextPlant = plant;
        break;
      }
    }
    
    // Level Logic (1 Level per 100kg)
    int level = (_carbonSaved / 100).floor() + 1;
    double progressToNext = (_carbonSaved % 100) / 100;
    if (nextPlant != null) {
       // Proportional progress to specific unlock
       double prevUnlock = 0;
       double target = (nextPlant['unlockAt'] as int).toDouble();
       // Find previous unlock
       int idx = _plants.indexOf(nextPlant);
       if (idx > 0) prevUnlock = (_plants[idx-1]['unlockAt'] as int).toDouble();
       
       progressToNext = (_carbonSaved - prevUnlock) / (target - prevUnlock);
       progressToNext = progressToNext.clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                // Parallax/Scrolling Effect
                return Stack(
                  children: [
                    Positioned(
                      left: -_bgController.value * MediaQuery.of(context).size.width,
                      top: 0, bottom: 0, width: MediaQuery.of(context).size.width,
                      child: Image.asset('assets/images/bg_game.jpg', fit: BoxFit.cover, color: Colors.black38, colorBlendMode: BlendMode.darken),
                    ),
                    Positioned(
                       left: (1 - _bgController.value) * MediaQuery.of(context).size.width,
                       top: 0, bottom: 0, width: MediaQuery.of(context).size.width,
                       child: Image.asset('assets/images/bg_game.jpg', fit: BoxFit.cover, color: Colors.black38, colorBlendMode: BlendMode.darken),
                    ),
                  ],
                );
              }
            ),
          ),
          
          // Foreground Content
          Positioned.fill(
            child: _isLoading  
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Stack(
            children: [
               // 0. The SUN (Animated)
                // 0. The SUN (Realistic)
                Positioned(
                  top: 50, right: 20,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white, Colors.yellow, Colors.orangeAccent, Colors.transparent],
                        stops: [0.1, 0.4, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
                        BoxShadow(color: Colors.yellowAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                      ]
                    ),
                  )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.05, duration: 4.seconds, curve: Curves.easeInOut), // Gentle Heat Pulse
                ),
             // 1. THE 3D WORLD (Behind everything)
             Positioned.fill(
               child: Column(
                 children: [
                    SizedBox(height: 120), // Spacing for HUD
                    Expanded(
                      child: GestureDetector(
                        onPanUpdate: _onPanUpdate,
                        child: Container(
                          color: Colors.transparent, // Hit test for full area
                          child: Center(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001) // Perspective
                                ..rotateX(_rotationX)
                                ..rotateY(_rotationY),
                              child: SizedBox(
                                width: 380,
                                height: 380,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                  _buildVolumetricSlab(380, 380, 60),
                                  Container(
                                    width: 380, height: 380,
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3, 
                                        childAspectRatio: 1.0
                                      ),
                                      itemCount: 9,
                                      itemBuilder: (context, index) => _buildGridItem(context, index),
                                    ),
                                  ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // SEED BANK (Bottom Dock)
                    _buildSeedDock(),
                 ],
               ),
             ),

             // 2. HEADS UP DISPLAY (HUD)
             Positioned(
               top: 0, left: 0, right: 0,
               child: SafeArea(
                 child: Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       begin: Alignment.topCenter, end: Alignment.bottomCenter,
                       colors: [Colors.black87, Colors.transparent], 
                       stops: [0.0, 1.0]
                     )
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // Top Row: Back + Title
                       Row(
                         children: [
                           IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                           Text("ECO FARM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2)),
                           Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amberAccent)),
                              child: Row(children: [Icon(Icons.star, color: Colors.amberAccent, size: 16), SizedBox(width: 4), Text("$_points", style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))]),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent)),
                              child: Row(children: [Icon(Icons.eco, color: Colors.greenAccent, size: 16), SizedBox(width: 4), Text("Health: 100%", style: TextStyle(color: Colors.greenAccent))]),
                            )
                         ],
                       ),
                       SizedBox(height: 16),
                       
                       // Level Progress
                       Row(
                         children: [
                           Container(
                             padding: EdgeInsets.all(8),
                             decoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.5), blurRadius: 10)]),
                             child: Text("$level", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                           ),
                           SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                   Text("Level $level Guardian", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                   Text("${_carbonSaved.toInt()} / ${nextPlant != null ? nextPlant['unlockAt'] : 'MAX'} CO₂", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                 ]),
                                 SizedBox(height: 6),
                                 ClipRRect(
                                   borderRadius: BorderRadius.circular(4),
                                   child: LinearProgressIndicator(value: progressToNext, backgroundColor: Colors.white10, color: Colors.greenAccent, minHeight: 6),
                                 ),
                               ],
                             )
                           )
                         ],
                       ),
                       
                       // Next Unlock Preview
                       if (nextPlant != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 12, left: 50), // Align with text
                           child: Row(
                             children: [
                               Text("Next Unlock: ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                               Text(nextPlant['name'], style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                               SizedBox(width: 8),
                               Icon(Icons.lock_outline, size: 12, color: Colors.white30)
                             ],
                           ),
                         )
                     ],
                   ),
                 ),
               ),
             ),
            ],
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildGridItem(BuildContext context, int index) {
      return DragTarget<Map<String, dynamic>>(
        onWillAccept: (plant) => _points >= (plant?['cost'] ?? 50),
        onAccept: (plant) {
           setState(() {
             _placedPlants[index] = plant;
             _points -= (plant['cost'] as int? ?? 50);
           });
           _decrementSeed(plant['name']); // Reduce Usage
        },
        builder: (context, candidates, rejects) {
          final plant = _placedPlants[index];
          final isHovered = candidates.isNotEmpty;

          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
              color: isHovered ? Colors.greenAccent.withOpacity(0.3) : Colors.transparent,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (plant != null) _buildAnimatedPlant(plant),
                if (isHovered && candidates.isNotEmpty)
                  Opacity(opacity: 0.6, child: _buildAnimatedPlant(candidates.first!, isGhost: true))
              ],
            ),
          );
        },
      );
  }

  Widget _buildSeedDock() {
      return Container(
         height: 110,
         margin: EdgeInsets.all(16),
         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         decoration: BoxDecoration(
           color: Colors.black54,
           borderRadius: BorderRadius.circular(24),
           border: Border.all(color: Colors.white12),
           boxShadow: [BoxShadow(color: Colors.black, blurRadius: 20)]
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text("SEED COLLECTION", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
             SizedBox(height: 8),
             Expanded(
                  child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _plants.map((plant) {
                    final isUnlocked = _carbonSaved >= (plant['unlockAt'] as int);
                    final canAfford = _points >= (plant['cost'] as int? ?? 50);
                    return Opacity(
                      opacity: isUnlocked && canAfford ? 1.0 : 0.3,
                      child: Container(
                        margin: EdgeInsets.only(right: 12),
                        child: isUnlocked && canAfford
                          ? Draggable<Map<String, dynamic>>(
                              data: plant,
                              feedback: Material(color: Colors.transparent, child: Image.asset(plant['image'], width: 60)),
                              child: _buildSeedItem(plant),
                              maxSimultaneousDrags: (plant['quantity'] ?? 5) > 0 ? 1 : 0, // Disable if empty
                            )
                         : _buildSeedItem(plant, locked: true),
                     ),
                   );
                 }).toList(),
               ),
             ),
           ],
         ),
      );
  }

  Widget _buildSeedItem(Map<String, dynamic> plant, {bool locked = false}) {
     int qty = plant['quantity'] ?? 5;
     return Container(
       width: 60,
       decoration: BoxDecoration(
         color: locked ? Colors.white10 : Colors.green.withOpacity(0.1),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: locked ? Colors.transparent : Colors.greenAccent.withOpacity(0.5))
       ),
       child: Stack(
         children: [
           Center(
             child: locked 
               ? Icon(Icons.lock, color: Colors.white24)
               : Image.asset(plant['image'], width: 40)
           ),
           if (!locked && qty > 0)
             Positioned(
               right: 4, bottom: 4,
               child: Container(
                 padding: EdgeInsets.all(4),
                 decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                 child: Text("$qty", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
               ),
             ),
            if (!locked && qty <= 0)
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 30),
                ),
              )
         ],
       ),
     );
  }


  // State for placed plants (Index -> Plant Data)
  final Map<int, Map<String, dynamic>> _placedPlants = {};

  Widget _buildSeedPacket(Map<String, dynamic> plant) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8D6E63),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          plant.containsKey('image')
            ? Image.asset(plant['image'] as String, width: 35, height: 35)
            : Icon(plant['icon'] as IconData, size: 30, color: Colors.greenAccent),
          const SizedBox(height: 4),
          Text(plant['name'], style: const TextStyle(fontSize: 10, color: Colors.white), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  // --- 3D Helpers ---

  Widget _buildVolumetricSlab(double width, double height, double depth) {
    // 1. Define Face Data (Widget + Center Point)
    final texture = const DecorationImage(
      image: AssetImage('assets/images/soil_texture.png'), 
      fit: BoxFit.cover, 
      colorFilter: ColorFilter.mode(Colors.black54, BlendMode.overlay)
    );

    // Side: Dark Earth
    final sideDecoration = BoxDecoration(
      color: const Color(0xFF3E2723), 
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFF5D4037), const Color(0xFF23110F)], 
      ),
      image: texture,
      border: Border.all(color: Colors.black38),
    );
    
    // Top: Garden Plot Look (Green Rim)
    final topDecoration = BoxDecoration(
      image: const DecorationImage(image: AssetImage('assets/images/soil_texture.png'), fit: BoxFit.cover),
      boxShadow: [BoxShadow(color: Colors.black45, spreadRadius: 2, blurRadius: 10, offset: Offset(0, 5))], 
      border: Border.all(color: const Color(0xFF33691E), width: 6), // Thick Grassy Border
      borderRadius: BorderRadius.circular(4), // Soft edges for garden feel
    );

    // List of faces: {id, x, y, z, widget}
    // Centered at (0,0,0)
    List<Map<String, dynamic>> faces = [
      // TOP (0, 0, 0)
      {
        'x': 0.0, 'y': 0.0, 'z': 0.0,
        'widget': Container(
           width: width, height: height,
           decoration: topDecoration,
           child: Container( // Inner shadow vignette
             decoration: BoxDecoration(
               gradient: RadialGradient(colors: [Colors.transparent, Colors.black26], radius: 0.8)
             ),
           ),
         )
      },
      // BOTTOM (0, 0, depth)
      {
        'x': 0.0, 'y': 0.0, 'z': depth,
        'widget': Transform(
           alignment: Alignment.center,
           transform: Matrix4.identity()..translate(0.0, 0.0, depth),
           child: Container(width: width, height: height, color: const Color(0xFF1B0D0B)),
         )
      },
      // FRONT (0, h/2, d/2)
      {
        'x': 0.0, 'y': height/2, 'z': depth/2,
        'widget': Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..translate(0.0, height / 2, depth / 2)..rotateX(-math.pi / 2), 
          child: Container(width: width, height: depth, decoration: sideDecoration.copyWith(
               border: Border(top: BorderSide(color: Colors.lightGreen[800]!, width: 4), bottom: BorderSide(color: Colors.black87, width: 8))
          )),
        )
      },
      // BACK (0, -h/2, d/2)
      {
        'x': 0.0, 'y': -height/2, 'z': depth/2,
        'widget': Transform(
           alignment: Alignment.center,
           transform: Matrix4.identity()..translate(0.0, -height / 2, depth / 2)..rotateX(math.pi / 2),
           child: Container(width: width, height: depth, decoration: sideDecoration.copyWith(color: const Color(0xFF23110F))),
         )
      },
      // RIGHT (w/2, 0, d/2)
      {
        'x': width/2, 'y': 0.0, 'z': depth/2,
        'widget': Transform(
             transform: Matrix4.identity()..translate(width / 2, 0.0, depth / 2)..rotateY(-math.pi / 2),
             alignment: Alignment.center,
             child: Container(width: depth, height: height, decoration: sideDecoration)
         )
      },
      // LEFT (-w/2, 0, d/2)
      {
        'x': -width/2, 'y': 0.0, 'z': depth/2,
        'widget': Transform(
           alignment: Alignment.center,
           transform: Matrix4.identity()..translate(-width / 2, 0.0, depth / 2)..rotateY(math.pi / 2),
           child: Container(width: depth, height: height, decoration: sideDecoration.copyWith(color: const Color(0xFF23110F))),
         )
      },
    ];

    faces.sort((a, b) {
      double zA = _calculateRotatedZ(a['x'], a['y'], a['z']);
      double zB = _calculateRotatedZ(b['x'], b['y'], b['z']);
      return zB.compareTo(zA); 
    });

    return Stack(
       clipBehavior: Clip.none,
       alignment: Alignment.center,
       children: faces.map((f) => f['widget'] as Widget).toList(),
    );
  }

  double _calculateRotatedZ(double x, double y, double z) {
     final double cosX = math.cos(_rotationX);
     final double sinX = math.sin(_rotationX);
     final double cosY = math.cos(_rotationY);
     final double sinY = math.sin(_rotationY);

     // 1. Rotate around X
     // y' = y*cosX - z*sinX
     // z' = y*sinX + z*cosX
     double z_temp = y * sinX + z * cosX;
     
     // 2. Rotate around Y
     // z'' = -x*sinY + z'*cosY
     double z_final = -x * sinY + z_temp * cosY;

     return z_final;
  }

  Widget _buildAnimatedPlant(Map<String, dynamic> plant, {bool isGhost = false}) {
     Widget content = plant.containsKey('image')
        ? Image.asset(
            plant['image'] as String, 
            width: 90, height: 90, fit: BoxFit.contain,
            color: plant['color'] as Color?,
            colorBlendMode: plant['blend'] as BlendMode?
          )
        : Icon(plant['icon'] as IconData, size: 60, color: Colors.lightGreenAccent);

     if (isGhost) return content;

     return Transform(
       alignment: Alignment.bottomCenter,
       transform: Matrix4.identity()
          ..rotateY(-_rotationY) 
          ..rotateX(-_rotationX) 
          ..translate(0.0, 10.0), // Slight sink for roots
       child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
            // The Plant
            content
             .animate(onPlay: (c) => c.repeat(reverse: true))
             .scaleXY(begin: 1.0, end: 1.08, duration: 2.seconds, curve: Curves.easeInOut) // Breathe
             .moveY(begin: 0, end: -4, duration: 2.5.seconds, curve: Curves.easeInOut), // Bob (Gentle)
         ],
       ),
     );
  }
}
