import 'package:flutter/material.dart';

class ScanModeToggle extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;

  const ScanModeToggle({
    Key? key, 
    required this.currentMode, 
    required this.onModeChanged
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOption("Quick Scan", "quick", Icons.speed),
          _buildOption("Deep Scan", "deep", Icons.psychology),
        ],
      ),
    );
  }

  Widget _buildOption(String label, String mode, IconData icon) {
    final bool isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (mode == 'quick' ? Colors.greenAccent : Colors.purpleAccent) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white54),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white54, 
                fontWeight: FontWeight.bold,
                fontSize: 13
              )
            ),
          ],
        ),
      ),
    );
  }
}
