import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ecosnap_frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  // Data
  List<dynamic> _products = [];
  List<dynamic> _services = [];
  Map<String, dynamic>? _solarDemo;
  bool _isLoading = true;
  String _selectedCategory = "solar_equipment";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final productsRes = await _apiService.getMarketplaceProducts(category: _selectedCategory);
      // For Services tab, we can filter or fetch separately. 
      // The backend returns all products if no category, or specific.
      // Let's fetch services specifically for that tab
      final servicesRes = await _apiService.getMarketplaceProducts(category: 'services');
      
      // Fetch Demo Solar System for ROI showcase
      final solarRes = await _apiService.getDemoSolarSystem(2.5);

      if (mounted) {
        setState(() {
          _products = productsRes['products'] ?? [];
          _services = servicesRes['products'] ?? [];
          _solarDemo = solarRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching marketplace: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCategoryChanged(String? newValue) async {
    if (newValue != null) {
      setState(() {
        _selectedCategory = newValue;
        _isLoading = true;
      });
      final res = await _apiService.getMarketplaceProducts(category: newValue);
      setState(() {
        _products = res['products'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Marketplace 🛒", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Tooltip(
              message: "Data verified from official government sources and certified partners",
              triggerMode: TooltipTriggerMode.tap, // Ensure tap works on mobile/web
              child: const Icon(Icons.verified, color: Colors.blue, size: 20),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Products"),
            Tab(text: "Services"),
            Tab(text: "Power Kits"), // Solar Demo
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildServicesTab(),
                _buildSolarKitTab(),
              ],
            ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Category Filter
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip("Solar Equipment", "solar_equipment", Icons.solar_power),
              _CategoryChip("Energy Efficient", "energy_efficient", Icons.bolt),
              _CategoryChip("Sustainable", "sustainable_products", Icons.eco),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final p = _products[i];
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
                        child: Icon(_getIconForCategory(p['category']), color: Colors.greenAccent, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Sold by: ${p['seller']?['name'] ?? 'Verified Seller'}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 8),
                            if (p['subsidy_eligible'] == true)
                               Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Text("Subsidy Eligible ✅", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("₹${p['price']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {}, 
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, minimumSize: const Size(80, 36)),
                            child: const Text("Buy"),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 100));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesTab() {
     return ListView.builder(
       padding: const EdgeInsets.all(16),
       itemCount: _services.length,
       itemBuilder: (ctx, i) {
         final s = _services[i];
         return Container(
           margin: const EdgeInsets.only(bottom: 16),
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.2), Colors.purple.withOpacity(0.2)]),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Icon(Icons.verified, color: Colors.blueAccent),
                  ],
                ),
                Text(s['seller']?['name'] ?? '', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${s['rating']} (${s['reviews_count']})", style: const TextStyle(color: Colors.white70)),
                    const Spacer(),
                    Text(s['price_range'] ?? "Contact for price", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueAccent)),
                    child: const Text("Book Service", style: TextStyle(color: Colors.blueAccent)),
                  ),
                )
             ],
           ),
         );
       },
     );
  }

  Widget _buildSolarKitTab() {
    if (_solarDemo == null) return const Center(child: Text("Loading demo..."));
    
    final pricing = _solarDemo?['pricing'] ?? {};
    final roi = _solarDemo?['roi'] ?? {};
    final components = _solarDemo?['components'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROI Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF2994A), Color(0xFFF2C94C)]),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
            ),
            child: Column(
              children: [
                 const Text("2.5kW Solar System Deal", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
                 const SizedBox(height: 20),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     _RoiStat("Net Cost", "₹${pricing['net_cost'] ?? '0'}", Colors.black),
                     _RoiStat("Annual Savings", "₹${roi['annual_savings'] ?? '0'}", Colors.black),
                     _RoiStat("Payback", "${roi['payback_period_years'] ?? '0'} yrs", Colors.black),
                   ],
                 ),
                 const SizedBox(height: 20),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
                   child: Text("Total 5-Year Profit: ₹${roi['five_year_profit'] ?? '0'}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                 )
              ],
            ),
          ),
          
          const SizedBox(height: 25),
          const Text("Package Components", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          _ComponentTile("Solar Panels", "${components['panels']?['quantity'] ?? '0'}x ${components['panels']?['product'] ?? 'Panels'}", Icons.grid_view),
          _ComponentTile("Inverter", "1x ${components['inverter']?['product'] ?? 'Inverter'}", Icons.electrical_services),
          _ComponentTile("Installation", "${components['installation']?['service'] ?? 'Standard'}", Icons.build),
          
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              child: const Text("Order Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _CategoryChip(String label, String id, IconData icon) {
    final isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () => _onCategoryChanged(id),
      child: Container(
        margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.greenAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.black : Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? cat) {
    if (cat == 'solar_equipment') return Icons.solar_power;
    if (cat == 'energy_efficient') return Icons.bolt;
    return Icons.eco;
  }
}

class _RoiStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _RoiStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}

class _ComponentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _ComponentTile(this.title, this.subtitle, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
