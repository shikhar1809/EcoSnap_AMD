import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _rewards = [];
  bool _isLoadingRewards = true;
  // Hardcoded for demo/MVP - assuming current user ID
  // In a real app, this would come from a tailored auth provider
  final String _demoUserId = "user_123"; 

  @override
  void initState() {
    super.initState();
    _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    try {
      final items = await _apiService.getMarketplaceItems();
      if (mounted) {
        setState(() {
          _rewards = items;
          _isLoadingRewards = false;
        });
      }
    } catch (e) {
      print("Error fetching rewards: $e");
      if (mounted) setState(() => _isLoadingRewards = false);
    }
  }

  Future<void> _redeem(String itemId, String itemName, int cost) async {
    try {
      // Optimistic/Loading UI could go here
      final result = await _apiService.redeemItem(_demoUserId, itemId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Redeemed '$itemName'! Remaining Points: ${result['remaining_points']}"),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: $e"),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Added Rewards Tab
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
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              tooltip: "Back to Home",
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.greenAccent,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.greenAccent,
            isScrollable: true,
            tabs: [
              Tab(text: "Rewards"), // New Tab First!
              Tab(text: "Sell Scrap"),
              Tab(text: "Repair Services"),
              Tab(text: "Buy Rebuilt"),
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
                   // 1. REWARDS (Backend Connected)
                   _isLoadingRewards 
                       ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                       : _buildRewardsList(),

                   // 2. SCRAPE (Mock)
                   _buildList("Scrape", [
                     {"name": "Old Metal Pipes", "price": "₹40/kg", "desc": "Rusted iron pipes, suitable for recycling.", "icon": Icons.build},
                     {"name": "E-Waste Mix", "price": "₹150/kg", "desc": "Mixed circuit boards and wires.", "icon": Icons.memory},
                     {"name": "Glass Bottles", "price": "₹5/pc", "desc": "Assorted glass bottles for crushing.", "icon": Icons.wine_bar},
                   ]),
                   
                   // 3. REPAIR (Mock)
                   _buildList("Repair", [
                     {"name": "Broken Toaster", "price": "₹200", "desc": "Needs heating element replacement.", "icon": Icons.breakfast_dining},
                     {"name": "Wobbly Chair", "price": "₹500", "desc": "Teak wood, needs leg glue and polish.", "icon": Icons.chair},
                     {"name": "Cycle (Flat Tyre)", "price": "₹1500", "desc": "Good frame, just needs tyres.", "icon": Icons.directions_bike},
                   ]),

                   // 4. REBUILT (Mock)
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

  Widget _buildRewardsList() {
    if (_rewards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text("No rewards available yet.", style: TextStyle(color: Colors.white54)),
            ElevatedButton(onPressed: _fetchRewards, child: const Text("Refresh"))
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      itemBuilder: (context, index) {
        final item = _rewards[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purpleAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.2)]
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard, color: Colors.purpleAccent, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(item['name'] ?? 'Reward', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     Text(item['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${item['cost_points']} Pts", style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _redeem(item['id'], item['name'], item['cost_points']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                    ),
                    child: const Text("Redeem"),
                  )
                ],
              )
            ],
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX();
      },
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
