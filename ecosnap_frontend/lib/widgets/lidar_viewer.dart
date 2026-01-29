import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class LidarViewer extends StatefulWidget {
  final Uint8List depthImageBytes;

  const LidarViewer({super.key, required this.depthImageBytes});

  @override
  State<LidarViewer> createState() => _LidarViewerState();
}

class _LidarViewerState extends State<LidarViewer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  img.Image? _decodedImage;
  bool _processing = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _processImage();
  }

  Future<void> _processImage() async {
    // Decode image in isolation (for MVP doing it here is fine)
    final image = img.decodeImage(widget.depthImageBytes);
    if (image != null) {
      // Resize for performance (60x60 grid is enough for cool wireframe)
      _decodedImage = img.copyResize(image, width: 60, height: 60);
    }
    if (mounted) setState(() => _processing = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_processing || _decodedImage == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LidarMeshPainter(
            depthMap: _decodedImage!,
            rotation: _controller.value * 2 * math.pi,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LidarMeshPainter extends CustomPainter {
  final img.Image depthMap;
  final double rotation;

  _LidarMeshPainter({required this.depthMap, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    final w = depthMap.width;
    final h = depthMap.height;
    
    // Grid spacing
    final dx = size.width / w;
    final dy = size.height / h;
    
    // Center of screen
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 3D Projection Calculation
    // Simple perspective projection with rotation around Y axis
    
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = depthMap.getPixel(x, y);
        // Intensity 0-255. In viridis, brighter is usually closer (or handled by backend)
        // Let's assume red channel holds intensity
        final intensity = pixel.r / 255.0; 
        
        // 3D Coordinates (Centered)
        double px = (x - w / 2) * dx;
        double py = (y - h / 2) * dy;
        double pz = intensity * 100; // Depth extrusion
        
        // Rotate around Y axis
        double rx = px * math.cos(rotation) - pz * math.sin(rotation);
        double rz = px * math.sin(rotation) + pz * math.cos(rotation);
        
        // Perspective divide (simple)
        double scale = 1000 / (1000 - rz); 
        
        double screenX = cx + rx * scale;
        double screenY = cy + py * scale;
        
        // Draw Points (Lidar Cloud Style)
        canvas.drawCircle(Offset(screenX, screenY), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LidarMeshPainter oldDelegate) => true;
}
