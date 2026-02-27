import 'package:flutter/material.dart';
import 'package:ecosnap_frontend/services/api_service.dart';
import 'package:intl/intl.dart';
import '../widgets/impact_passport.dart';
import '../widgets/sdg_badges.dart';
import '../widgets/green_ai_metrics.dart';

/// Impact Passport Screen - Shows user's verified sustainability credentials
/// Merged with Carbon Module (CCTS, Wallet, Offsets) for a unified experience
class ImpactPassportScreen extends StatefulWidget {
  const ImpactPassportScreen({super.key});

  @override
  State<ImpactPassportScreen> createState() => _ImpactPassportScreenState();
}

class _ImpactPassportScreenState extends State<ImpactPassportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final String userId = "test_user_id"; // Demo user

  // Carbon Data
  Map<String, dynamic>? _walletData;
  Map<String, dynamic>? _marketPrice;
  List<dynamic> _offsetProjects = [];
  bool _isLoading = true;

  // CCTS Form
  String? _selectedSector;
  final TextEditingController _emissionsController = TextEditingController();
  final TextEditingController _productionController = TextEditingController();
  Map<String, dynamic>? _complianceResult;

  final List<String> _sectors = [
    'cement', 'iron_steel', 'aluminium', 'chlor_alkali', 
    'fertilizer', 'paper_pulp', 'petrochemical', 'refinery', 'textile'
  ];

  @override
  void initState() {
    super.initState();
    // 4 Tabs: Passport, Wallet, Compliance, Offsets
    _tabController = TabController(length: 4, vsync: this);
    _fetchCarbonData();
  }

  Future<void> _fetchCarbonData() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await _apiService.getCarbonWallet(userId);
      final price = await _apiService.getMarketPrice();
      final projects = await _apiService.getOffsetProjects(userId);

      if (mounted) {
        setState(() {
          _walletData = wallet ?? {};
          // 🚀 DEMO DATA INJECTION
          if (_walletData!['ccc_balance'] == null || _walletData!['ccc_balance'] == 0) {
            _walletData = Map<String, dynamic>.from(_walletData!);
            _walletData!['ccc_balance'] = 12.50; // Demo: 12.5 Credits
            _walletData!['net_emissions_tco2'] = 1.8; // Demo: Low footprint
            _walletData!['recommendations'] = [
               "Switch to 5-star AC to save ~₹4,000/yr",
               "Install solar panels for 80% subsidy",
               "Compost kitchen waste to reduce methane"
            ];
          }
          
          _marketPrice = price;
          _offsetProjects = projects['projects'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateCompliance() async {
    if (_selectedSector == null || _emissionsController.text.isEmpty || _productionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      final result = await _apiService.calculateCompliance(
        _selectedSector!,
        double.parse(_emissionsController.text),
        double.parse(_productionController.text),
      );
      setState(() => _complianceResult = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text("Eco-Wallet & Passport", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: "PASSPORT"),
            Tab(text: "MY WALLET"),
            Tab(text: "COMPLIANCE"),
            Tab(text: "OFFSETS"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPassportTab(),
                _buildWalletTab(),
                _buildComplianceTab(),
                _buildOffsetTab(),
              ],
            ),
    );
  }

  Widget _buildPassportTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Main Passport Card
          ImpactPassport(
            userName: "Eco Warrior", // Could be from user state
            totalCo2Saved: 127.5, // Could be from insights
            scansCompleted: 42,
            treesEquivalent: 6,
            ecoLevel: "Climate Champion",
            memberSince: DateTime.now().subtract(const Duration(days: 45)),
            verificationHash: "0xVERIFIED_HASH_DEMO",
            carbonCreditsBalance: _walletData?['ccc_balance'] ?? 12.50,
          ),
          
          const SizedBox(height: 10),
          const GreenAiMetrics(),
          const SizedBox(height: 20),
          
          // SDG Contribution Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "YOUR UN SDG CONTRIBUTIONS",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                const SdgImpactSummary(
                  journey: 'PRODUCT_SCAN',
                  co2Saved: 127.5,
                  energySaved: 245.2,
                ),
                const SizedBox(height: 20),
                
                // Recent Activity
                const Text(
                  "RECENT IMPACT ACTIVITY",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivityItem("🌞", "Solar Audit", "Identified 3kW potential", "2 days ago"),
                _buildActivityItem("📦", "Product Scan", "Found 3 eco alternatives", "3 days ago"),
                _buildActivityItem("🏠", "Room Audit", "5 vampire power sources", "5 days ago"),
                _buildActivityItem("📄", "Bill Analysis", "₹2,400/yr savings found", "1 week ago"),
              ],
            ),
          ),
          
          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildWalletTab() {
    final balance = _walletData?['ccc_balance'] ?? 12.50;
    final ecoTokens = (balance * 100).toInt(); // Conversion rate

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF232526), Color(0xFF414345)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amberAccent.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: Colors.amberAccent.withOpacity(0.2), blurRadius: 20)],
            ),
            child: Column(
              children: [
                const Text("Total EcoTokens Mined ⛏️", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 40),
                    const SizedBox(width: 10),
                    Text("$ecoTokens", style: const TextStyle(color: Colors.amberAccent, fontSize: 48, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("≈ ₹${NumberFormat('#,##,###').format(ecoTokens * 2.5)} Value", style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(icon: Icons.qr_code_scanner, label: "Pay/Redeem", onTap: () {}),
                    _ActionButton(icon: Icons.swap_horiz, label: "Swap to Fiat", onTap: () {}),
                    _ActionButton(icon: Icons.send, label: "Send to Friend", onTap: () {}),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Storefront
          const Row(
            children: [
               Icon(Icons.storefront, color: Colors.white),
               SizedBox(width: 8),
               Text("Rewards Storefront 🛍️", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]
          ),
          const SizedBox(height: 15),
          
          _buildRewardItem("5% Off Solar Installation", 5000, Icons.solar_power, Colors.orangeAccent),
          _buildRewardItem("Free EV Charging Session (1hr)", 500, Icons.ev_station, Colors.blueAccent),
          _buildRewardItem("Plant a Tree in your name", 250, Icons.forest, Colors.green),
          _buildRewardItem("1 Month Premium Eco-Stats", 100, Icons.analytics, Colors.purpleAccent),
          
          const SizedBox(height: 20),
          // Household Emissions Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Carbon Footprint", style: TextStyle(color: Colors.white70)),
                    Text("1.8 tCO2e / yr", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Icon(Icons.eco, color: Colors.greenAccent, size: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String title, int cost, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 14),
                const SizedBox(width: 4),
                Text("$cost", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildComplianceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("CCTS 2023 Compliance 🏭", style: TextStyle(color: Colors.green[300], fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Calculate CCC obligations for designated consumers.", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          
          // Form
          DropdownButtonFormField<String>(
            value: _selectedSector,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Select Sector"),
            items: _sectors.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _selectedSector = v),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _emissionsController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration("Annual Emissions (tCO2e)"),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _productionController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration("Annual Production (tonnes)"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _calculateCompliance,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Calculate Compliance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 30),

          // Output
          if (_complianceResult != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _complianceResult!['status'] == 'SURPLUS' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _complianceResult!['status'] == 'SURPLUS' ? Colors.green : Colors.red),
              ),
              child: Column(
                children: [
                  Icon(
                    _complianceResult!['status'] == 'SURPLUS' ? Icons.check_circle : Icons.warning,
                    color: _complianceResult!['status'] == 'SURPLUS' ? Colors.green : Colors.red,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _complianceResult!['status'] == 'SURPLUS' ? "CCC SURPLUS" : "CCC DEFICIT",
                    style: TextStyle(
                      color: _complianceResult!['status'] == 'SURPLUS' ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _complianceResult!['message'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const Divider(color: Colors.white24, height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DataPoint("Actual Intensity", _complianceResult!['actual_intensity'].toString()),
                      _DataPoint("Target Intensity", _complianceResult!['target_intensity'].toString()),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_complianceResult!['status'] == 'SURPLUS')
                    Text("Estimated Value: ₹${_complianceResult!['estimated_value']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
                  else
                    Text("Estimated Cost: ₹${_complianceResult!['estimated_cost']}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOffsetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Verified Offset Projects 🌱", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("BEE-approved projects for voluntary carbon credits.", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),

          // Project List
          if (_offsetProjects.isEmpty)
             const Center(child: Padding(
               padding: EdgeInsets.all(20.0),
               child: Text("No projects found. Start a new one!", style: TextStyle(color: Colors.white30)),
             ))
          else
            ..._offsetProjects.map((p) => Card(
              color: Colors.white.withOpacity(0.05),
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.solar_power, color: Colors.blueAccent),
                ),
                title: Text(p['project_name'] ?? 'Unknown Project', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text("${p['credits_earned']} CCCs Earned", style: const TextStyle(color: Colors.greenAccent)),
                    Text("Status: ${p['status']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
              ),
            )).toList(),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              // Navigate to create project (future scope)
            },
            icon: const Icon(Icons.add, color: Colors.greenAccent),
            label: const Text("Submit New Project", style: TextStyle(color: Colors.greenAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.greenAccent),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActivityItem(String icon, String title, String description, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.greenAccent)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
        ],
      ),
    );
  }
}

class _DataPoint extends StatelessWidget {
  final String label;
  final String value;
  const _DataPoint(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
