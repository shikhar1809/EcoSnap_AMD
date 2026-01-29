import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text("Eco Marketplace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.greenAccent,
            tabs: [
              Tab(text: "Scrape"),
              Tab(text: "Repair"),
              Tab(text: "Rebuilt"),
            ],
          ),
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
              child: TabBarView(
                children: [
                   _buildList("Scrape", [
                     {"name": "Old Metal Pipes", "price": "₹40/kg", "desc": "Rusted iron pipes, suitable for recycling.", "icon": Icons.build},
                     {"name": "E-Waste Mix", "price": "₹150/kg", "desc": "Mixed circuit boards and wires.", "icon": Icons.memory},
                     {"name": "Glass Bottles", "price": "₹5/pc", "desc": "Assorted glass bottles for crushing.", "icon": Icons.wine_bar},
                   ]),
                   _buildList("Repair", [
                     {"name": "Broken Toaster", "price": "₹200", "desc": "Needs heating element replacement.", "icon": Icons.breakfast_dining},
                     {"name": "Wobbly Chair", "price": "₹500", "desc": "Teak wood, needs leg glue and polish.", "icon": Icons.chair},
                     {"name": "Cycle (Flat Tyre)", "price": "₹1500", "desc": "Good frame, just needs tyres.", "icon": Icons.directions_bike},
                   ]),
                   _buildList("Rebuilt", [
                     {"name": "Upcycled Tire Ottoman", "price": "₹1200", "desc": "Comfy seat made from old tires.", "icon": Icons.weekend},
                     {"name": "Pallet Coffee Table", "price": "₹2500", "desc": "Rustic table from shipping pallets.", "icon": Icons.table_restaurant},
                     {"name": "PCB Keychain", "price": "₹150", "desc": "Cool keychain from old motherboards.", "icon": Icons.key},
                   ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String category, List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'] as IconData, color: Colors.greenAccent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(item['desc'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['price'] as String, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(60, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text("View", style: TextStyle(fontSize: 12)),
                  )
                ],
              )
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX();
      },
    );
  }
}
