import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ScanButton({
    super.key, 
    required this.onTap, 
    required this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple 1
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent.withOpacity(0.1), width: 1),
          ),
        ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds).fadeOut(),
        
        // Ripple 2
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent.withOpacity(0.15), width: 1),
          ),
        ).animate(delay: 500.ms, onPlay: (c) => c.repeat()).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 2.seconds).fadeOut(),

        // Button
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.greenAccent.withOpacity(0.2), 
                  Colors.blueAccent.withOpacity(0.2)
                ],
                stops: const [0.2, 0.9]
              ),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 30, spreadRadius: -5, offset: const Offset(-10, -10))
              ]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Icon(Icons.camera_alt, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text("Tap to Snap", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                const SizedBox(
                  height: 20,
                  child: _RotatingText(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RotatingText extends StatefulWidget {
  const _RotatingText({Key? key}) : super(key: key);

  @override
  State<_RotatingText> createState() => _RotatingTextState();
}

class _RotatingTextState extends State<_RotatingText> {
  int _index = 0;
  final List<String> _texts = [
    "Try Snapping Your Room",
    "Scan an Electricity Bill", 
    "Check Furniture Value",
    "Identify Eco-Products"
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _rotate);
  }

  void _rotate() {
    if (!mounted) return;
    setState(() {
      _index = (_index + 1) % _texts.length;
    });
    Future.delayed(const Duration(seconds: 3), _rotate);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(animation),
          child: child
        ));
      },
      child: Text(
        _texts[_index],
        key: ValueKey<int>(_index),
        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
      ),
    );
  }
}
