import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/leaf_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:typed_data';
import '../widgets/scanner_loading.dart';
import 'chat_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService();
  bool _isAnalyzing = false;
  Uint8List? _currentImageBytes;

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes(); // Read bytes immediately
      if (mounted) {
         setState(() {
           _isAnalyzing = true;
           _currentImageBytes = bytes; // Store bytes for scanner
         });
      }
      
      // Artificial delay to show the scanner animation
      await Future.delayed(const Duration(seconds: 4)); // Increased to match new animation
      
      try {
        final result = await apiService.uploadImage(bytes, image.name);
        
        if (mounted) {
           setState(() => _isAnalyzing = false); // Stop scanning
           _showResults(result, bytes);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showResults(Map<String, dynamic> data, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with Markers
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                    // Markers
                    if (data['detected_objects'] != null)
                      ...((data['detected_objects'] as List).map((obj) {
                         if (obj is! Map || obj['box'] == null) return const SizedBox();
                         final box = obj['box'] as List; // [x1, y1, x2, y2] normalized
                         final cx = (box[0] + box[2]) / 2;
                         final cy = (box[1] + box[3]) / 2;
                         return Positioned.fill(
                           child: Align(
                             alignment: FractionalOffset(cx, cy),
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                   decoration: BoxDecoration(
                                     color: Colors.green.withOpacity(0.9),
                                     borderRadius: BorderRadius.circular(4),
                                     border: Border.all(color: Colors.white, width: 1),
                                     boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                   ),
                                   child: Text(
                                     obj['label'] ?? '', 
                                     style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                   ),
                                 ),
                                 const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                               ],
                             ),
                           ),
                         );
                      }).toList()),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Efficiency Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Efficiency Score:', style: TextStyle(fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${data['efficiency_score'] ?? '0'}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Green Architecture Section
                      if (data['green_architecture'] != null) ...[
                        Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.green.withOpacity(0.08),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.green.withOpacity(0.2)),
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                const Row(children: [
                                  Icon(Icons.architecture, color: Colors.green), 
                                  SizedBox(width: 8), 
                                  Text('Green Architecture', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16))
                                ]),
                                const SizedBox(height: 12),
                                const Text('Layout Advice:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(data['green_architecture']['layout_advice'] ?? 'No advice available.', style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 12),
                                const Text('Sustainable Additions:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Text(data['green_architecture']['sustainable_additions'] ?? 'None.', style: const TextStyle(fontSize: 14)),
                             ]
                           )
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Recommendation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Row(children: [Icon(Icons.lightbulb, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Recommendation:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
                             const SizedBox(height: 4),
                             Text(data['recommendation'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
                           ]
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
  // ... inside _showResults
                      // Appliances
                      const Text('Appliances Detected:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      if ((data['appliances'] as List?)?.isEmpty ?? true)
                        const Padding(padding: EdgeInsets.only(top: 8), child: Text('No appliances identified')),
                      ...(data['appliances'] as List? ?? []).map((a) => 
                        Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.only(top: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(a['type'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    Text(a['efficiency_rating'] ?? '', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const Divider(),
                                _infoRow("Brand", a['brand']),
                                _infoRow("Current Power", a['current_power_consumption']),
                                _infoRow("Est. Age", a['estimated_age']),
                                if (a['payback_period'] != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("💡 AI Recommendation", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text("Replace with: ${a['recommended_replacement']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text("Payback Period: ${a['payback_period']}", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                        Text("Save: ${a['financial_savings_year']}/yr", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        if (a['affiliate_link'] != null)
                                           Padding(
                                             padding: const EdgeInsets.only(top: 8),
                                             child: ElevatedButton.icon(
                                               onPressed: () {}, // Launch URL
                                               icon: const Icon(Icons.shopping_cart, size: 16),
                                               label: const Text("Buy on Flipkart"),
                                               style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 36)),
                                             ),
                                           )
                                      ],
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(userId: "user_id_placeholder", initialContext: "My ${data['appliances']?[0]['type'] ?? 'Room'} Analysis"))); 
             },
             child: const Text('Ask Expert', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build check
    if (_isAnalyzing) {
       return ScannerLoadingWidget(imageBytes: _currentImageBytes);
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40)
             .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(width: 10),
            const Text('EcoSnap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
             .animate().fadeIn(duration: 600.ms, delay: 200.ms),
          ],
        ),
        actions: [
           IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))
          ),
           IconButton(
            icon: const Icon(Icons.chat_bubble, color: Colors.greenAccent), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(userId: "user_id_placeholder"))) // In real app, get actual ID
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70), 
            onPressed: () => context.go('/login')
          )
        ],
      ),
      // ... rest of Scaffold body logic

      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),
          
          // Decorative Circles (2D Elements)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.1)),
            ),
          ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut).then().shimmer(duration: 2.seconds),
          
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)),
            ),
          ).animate(delay: 500.ms).scale(duration: 2.seconds, curve: Curves.easeInOut),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Text("Snap your room,\nSave the planet.", 
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2))
                    .animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 10),
                  Text("AI-powered analysis to get the best ROI and reduce your carbon footprint.", 
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)))
                    .animate(delay: 400.ms).fadeIn(),
                  
                  const Spacer(),
                  
                  // Glassmorphism Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                      ]
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 50, color: Colors.greenAccent)
                         .animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1), duration: 1.seconds),
                        const SizedBox(height: 16),
                        const Text("Ready to analyze?", 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                         Text("Upload a clear photo of your living space.", 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _uploadImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: const Text('Start Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 600.ms).slideY(begin: 0.2, end: 0).fadeIn(),
                  
                  const Spacer(),
                  
                  // Bottom Stats
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       Column(children: [Text("250+", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Users", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                       Column(children: [Text("120kg", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("CO2 Saved", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                       Column(children: [Text("4.8★", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Rating", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                    ],
                  ).animate(delay: 800.ms).fadeIn(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
