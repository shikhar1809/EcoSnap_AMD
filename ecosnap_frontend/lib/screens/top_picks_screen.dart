import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopPicksScreen extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const TopPicksScreen({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    final products = [
      {
        "name": "5-Star Inverter AC",
        "category": "Appliance",
        "price": "₹35,000",
        "savings": "Save ₹8,000/yr",
        "description": "Ultra-efficient cooling with AI energy management.",
        "image": "assets/images/ac_placeholder.png", // specific asset or icon
        "icon": Icons.ac_unit
      },
      {
        "name": "Bamboo Plates",
        "category": "Eco-Alternative",
        "price": "₹400 / pack",
        "savings": "Biodegradable",
        "description": "Sturdy, compostable functionality for parties.",
        "image": "assets/images/plate_placeholder.png",
        "icon": Icons.dinner_dining
      },
      {
        "name": "Solar Water Heater",
        "category": "Energy",
        "price": "₹20,000",
        "savings": "Zero Bill",
        "description": "Harness the sun for unlimited hot water.",
        "image": "assets/images/solar_placeholder.png",
        "icon": Icons.wb_sunny
      },
      {
        "name": "LED Smart Bulbs",
        "category": "Lighting",
        "price": "₹800",
        "savings": "80% Less Power",
        "description": "App-controlled lighting that lasts 10 years.",
        "image": "assets/images/bulb_placeholder.png",
        "icon": Icons.lightbulb
      }
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Eco Top Picks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          ),
        ],
      ),
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
          
          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(product['icon'] as IconData, color: Colors.greenAccent, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product['category'] as String, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(product['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(product['description'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                              child: Text(product['savings'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(product['price'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16)
                        ],
                      )
                    ],
                  ),
                ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
