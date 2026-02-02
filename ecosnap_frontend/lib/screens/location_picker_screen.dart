import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Default to a central location (Lucknow as developed demo region)
  // In a real app, use Geolocator to get current user position
  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(26.8467, 80.9462),
    zoom: 18.0, // High zoom for house level detail
    tilt: 45.0, // 3D effect
  );

  LatLng _pickedLocation = const LatLng(26.8467, 80.9462);
  bool _isLoading = false;

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onCameraMove(CameraPosition position) {
    _pickedLocation = position.target;
  }

  void _confirmLocation() {
    Navigator.pop(context, _pickedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid, // Satellite + Roads for context
            initialCameraPosition: _kDefaultLocation,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            buildingsEnabled: true, // Show 3D buildings
            tiltGesturesEnabled: true,
          ),
          
          // Center Pin Marker (Fixed in center of screen)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Icon(Icons.location_on, color: Colors.redAccent, size: 50),
            ),
          ),
          
          // Header UI
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)]
              ),
              child: Row(
                children: const [
                  Icon(Icons.satellite_alt, color: Colors.greenAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Pinpoint Your House", 
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5
              ),
              child: const Text("CONFIRM LOCATION FOR ANALYSIS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
