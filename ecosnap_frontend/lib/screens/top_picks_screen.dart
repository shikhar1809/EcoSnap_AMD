import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ecosnap_frontend/services/api_service.dart';

class TopPicksScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const TopPicksScreen({super.key, this.initialData});

  @override
  State<TopPicksScreen> createState() => _TopPicksScreenState();
}

class _TopPicksScreenState extends State<TopPicksScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> products = [];

  // Icon mapping for product categories
  static final Map<String, IconData> _categoryIcons = {
    'solar_equipment': Icons.wb_sunny,
    'energy_efficient': Icons.bolt,
    'sustainable_products': Icons.eco,
    'services': Icons.build,
  };

  // Fallback products if API fails
  static final List<Map<String, dynamic>> _fallbackProducts = [
    {
      "name": "5-Star Inverter AC",
      "category": "energy_efficient",
      "price": 35000,
      "savings": "Save ₹8,000/yr",
      "description": "Ultra-efficient cooling with AI energy management.",
      "icon": Icons.ac_unit
    },
    {
      "name": "Bamboo Plates (Pack of 50)",
      "category": "sustainable_products",
      "price": 400,
      "savings": "Biodegradable",
      "description": "Sturdy, compostable functionality for parties.",
      "icon": Icons.dinner_dining
    },
    {
      "name": "Solar Water Heater 200L",
      "category": "solar_equipment",
      "price": 20000,
      "savings": "Zero Bill",
      "description": "Harness the sun for unlimited hot water.",
      "icon": Icons.wb_sunny
    },
    {
      "name": "LED Smart Bulbs (Pack of 4)",
      "category": "energy_efficient",
      "price": 800,
      "savings": "80% Less Power",
      "description": "App-controlled lighting that lasts 10 years.",
      "icon": Icons.lightbulb
    },
    {
      "name": "BLDC Ceiling Fan",
      "category": "energy_efficient",
      "price": 3500,
      "savings": "65% Less Power",
      "description": "Brushless motor fan consuming only 28W.",
      "icon": Icons.air
    },
    {
      "name": "Compost Bin (Home)",
      "category": "sustainable_products",
      "price": 1200,
      "savings": "50kg waste/month",
      "description": "Convert kitchen waste into nutrient-rich compost.",
      "icon": Icons.recycling
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getMarketplaceProducts();
      if (response.containsKey('products') && (response['products'] as List).isNotEmpty) {
        final apiProducts = (response['products'] as List).map((p) {
          final cat = (p['category'] ?? '').toString();
          return <String, dynamic>{
            "name": p['name'] ?? 'Product',
            "category": cat,
            "price": p['price'] ?? 0,
            "savings": p['savings_per_year'] != null ? "Save ₹${p['savings_per_year']}/yr" : (p['eco_label'] ?? 'Eco-Friendly'),
            "description": p['description'] ?? '',
            "icon": _categoryIcons[cat] ?? Icons.eco,
            "rating": p['rating'] ?? 4.0,
            "seller": p['seller_name'] ?? '',
          };
        }).toList();
        setState(() {
          products = List<Map<String, dynamic>>.from(apiProducts);
          _isLoading = false;
        });
      } else {
        setState(() {
          products = _fallbackProducts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching top picks: $e");
      setState(() {
        products = _fallbackProducts;
        _isLoading = false;
      });
    }
  }

  String _formatPrice(dynamic price) {
    if (price is num) {
      if (price >= 1000) {
        return "₹${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k";
      }
      return "₹$price";
    }
    return "₹$price";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Eco Top Picks 🌿", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : ListView.builder(
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
                                Text(
                                  (product['category'] as String).replaceAll('_', ' ').toUpperCase(), 
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)
                                ),
                                Text(product['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                                  child: Text(product['savings'] as String, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 12),
                                // Auto-Pilot Upcycle Button
                                GestureDetector(
                                  onTap: () => _showUpcycleModal(product),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.recycling, color: Colors.blueAccent, size: 14),
                                        SizedBox(width: 4),
                                        Text("Auto-Sell Old Appliance", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(_formatPrice(product['price']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

  void _showUpcycleModal(Map<String, dynamic> newProduct) {
    String oldItemName = widget.initialData?['product_name'] ?? widget.initialData?['item_name'] ?? "Old Appliance";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Text("AI Listing Draft", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text("eBay Demo", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 30),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Container(
                       width: double.infinity,
                       height: 150,
                       decoration: BoxDecoration(
                         color: Colors.black45,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: Colors.white10),
                       ),
                       child: const Center(child: Icon(Icons.add_a_photo, color: Colors.white38, size: 40)),
                     ),
                     const SizedBox(height: 20),
                     const Text("Title", style: TextStyle(color: Colors.white54, fontSize: 12)),
                     const SizedBox(height: 4),
                     Text("Used $oldItemName - Good Condition", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                     
                     const Text("Price Estimate", style: TextStyle(color: Colors.white54, fontSize: 12)),
                     const SizedBox(height: 4),
                     const Text("₹2,500 - ₹4,000", style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 16),
                     
                     const Text("AI Generated Description", style: TextStyle(color: Colors.white54, fontSize: 12)),
                     const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.05),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         "Selling my used $oldItemName. It's fully functional but I am upgrading to a more energy-efficient model (${newProduct['name']}). Great for anyone needing a reliable backup appliance or parts. Local pickup preferred.",
                         style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                       ),
                     ),
                  ],
                ),
              ),
            ),
            
            // Action Button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Auto-published to Marketplace! ✅")));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("1-Click Publish Listing", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
