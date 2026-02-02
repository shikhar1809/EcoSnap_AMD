import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/simple_analysis_screen.dart';

/// WORKING SCAN BUTTON - NO BULLSHIT
class WorkingScanButton extends StatelessWidget {
  const WorkingScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        
        if (image != null) {
          final bytes = await image.readAsBytes();
          
          // DIRECT NAVIGATION - NO COMPLEX FLOWS
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleAnalysisScreen(
                imageBytes: bytes,
                imageName: image.name,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.greenAccent, Colors.green.shade700],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 60, color: Colors.white),
            SizedBox(height: 10),
            Text(
              'TAP TO SCAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
