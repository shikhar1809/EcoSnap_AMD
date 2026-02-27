import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class Warrior3DScreen extends StatefulWidget {
  final bool isMale;
  final String? equippedHelmet;
  final String? equippedArmor;
  final String? equippedShield;
  final Function(bool) onGenderChanged;

  const Warrior3DScreen({
    Key? key,
    required this.isMale,
    this.equippedHelmet,
    this.equippedArmor,
    this.equippedShield,
    required this.onGenderChanged,
  }) : super(key: key);

  @override
  State<Warrior3DScreen> createState() => _Warrior3DScreenState();
}

class _Warrior3DScreenState extends State<Warrior3DScreen> with SingleTickerProviderStateMixin {
  late bool _isMale;
  // Tilt variables
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  @override
  void initState() {
    super.initState();
    _isMale = widget.isMale;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Sensitivity factor
      _rotationY += details.delta.dx * 0.01; 
      _rotationX -= details.delta.dy * 0.01;
      
      // Clamp tilt to avoid flipping over completely
      _rotationX = _rotationX.clamp(-0.5, 0.5);
    });
  }

  void _resetOrientation() {
      setState(() {
        _rotationX = 0.0;
        _rotationY = 0.0;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
            // Ambient Background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [Color(0xFF1A237E), Colors.black],
                  stops: [0.0, 1.0]
                )
              ),
            ),
            
            // Particles (Simple simulated stars/dust)
             ...List.generate(20, (index) => Positioned(
                left: math.Random().nextDouble() * MediaQuery.of(context).size.width,
                top: math.Random().nextDouble() * MediaQuery.of(context).size.height,
                child: Container(
                  width: math.Random().nextDouble() * 3,
                  height: math.Random().nextDouble() * 3,
                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.3), shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat()).fade(duration: (1000 + math.Random().nextInt(2000)).ms)
             )),

            // Main Content
            Column(
              children: [
                // Custom App Bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text("LEGACY AVATAR", style: TextStyle(color: Colors.greenAccent, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold)),
                         IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _resetOrientation,
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: (_) => _resetOrientation(), // Optional: return to center on release
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _rotationY),
                        duration: 300.ms,
                        builder: (context, rY, nav) {
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Perspective
                              ..rotateX(_rotationX)
                              ..rotateY(rY),
                            alignment: Alignment.center,
                            child: _buildHeroCard(),
                          );
                        }
                      ),
                    ),
                  ),
                ),

                // Controls
                 Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                    )
                  ),
                  child: Column(
                    children: [
                      const Text("DRAG TO ROTATE", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 3)),
                      const SizedBox(height: 20),
                      Text(
                        _isMale ? "ECO VANGUARD" : "NATURE'S FURY",
                         style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Courier'),
                      ).animate().shimmer(duration: 2000.ms),
                      const SizedBox(height: 8),
                       Text(
                        "Level 3 • Sustainable Warrior",
                         style: TextStyle(color: Colors.greenAccent),
                      ),
                    ],
                  ),
                 )
              ],
            )
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: -5,
            offset: Offset(-_rotationY * 20, _rotationX * 20) // Shadow moves opposite to tilt
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The Hero Image
            Image.asset(
              'assets/images/warrior_render.png',
              fit: BoxFit.cover,
            ),
            
            // Holographic Gear Overlays
            if (widget.equippedHelmet != null)
              Positioned(
                top: 30,
                left: 0, right: 0,
                child: Center(
                  child: Icon(_getIconForGear(widget.equippedHelmet!), color: _getColorForGear(widget.equippedHelmet!).withOpacity(0.85), size: 100)
                    .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds).fadeIn(),
                ),
              ),
            if (widget.equippedArmor != null)
              Positioned(
                top: 150,
                left: 0, right: 0,
                child: Center(
                  child: Icon(_getIconForGear(widget.equippedArmor!), color: _getColorForGear(widget.equippedArmor!).withOpacity(0.85), size: 160)
                    .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds).fadeIn(),
                ),
              ),
            if (widget.equippedShield != null)
              Positioned(
                bottom: 100,
                right: 20,
                child: Icon(_getIconForGear(widget.equippedShield!), color: _getColorForGear(widget.equippedShield!).withOpacity(0.85), size: 120)
                  .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds).fadeIn()
                  .slide(begin: const Offset(0.1, 0)),
              ),
            
            // Holographic Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1 + (_rotationX.abs() * 0.2)),
                    Colors.transparent,
                    Colors.black.withOpacity(0.3)
                  ],
                  stops: [0.0, 0.5, 1.0]
                )
              ),
            ),
            
            // Border Glow
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3),
                  width: 2
                )
              ),
            ),
            
            // Floating UI Elements on Card
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Icon(Icons.shield, color: Colors.blueAccent, size: 16),
                       SizedBox(width: 4),
                       Text("DEF: 85", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                     ],
                   ),
                   SizedBox(height: 4),
                   Row(
                     children: [
                       Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                       SizedBox(width: 4),
                       Text("ATK: 120", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                     ],
                   )
                ],
              ),
            ),
            
             // Rare visual tag
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4)
                ),
                child: Text("LEGENDARY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _getIconForGear(String gearName) {
    if (gearName.contains("Forest")) return Icons.shield_moon;
    if (gearName.contains("Solar")) return Icons.wb_sunny;
    if (gearName.contains("Recycle")) return Icons.recycling;
    if (gearName.contains("Wings")) return Icons.flight;
    if (gearName.contains("Ocean")) return Icons.water_drop;
    return Icons.security; // default
  }

  Color _getColorForGear(String gearName) {
    if (gearName.contains("Forest")) return Colors.greenAccent;
    if (gearName.contains("Solar")) return Colors.orangeAccent;
    if (gearName.contains("Recycle")) return Colors.blueAccent;
    if (gearName.contains("Wings")) return Colors.purpleAccent;
    if (gearName.contains("Ocean")) return Colors.cyanAccent;
    return Colors.white; // default
  }
}
