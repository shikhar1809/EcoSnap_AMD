import 'package:flutter/material.dart';
import 'package:ecosnap_frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class CarbonScreen extends StatefulWidget {
  const CarbonScreen({Key? key}) : super(key: key);

  @override
  _CarbonScreenState createState() => _CarbonScreenState();
}

class _CarbonScreenState extends State<CarbonScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  final String userId = "test_user_id"; // Demo user

  // Data
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
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final wallet = await _apiService.getCarbonWallet(userId);
      final price = await _apiService.getMarketPrice();
      final projects = await _apiService.getOffsetProjects(userId);

      setState(() {
        _walletData = wallet;
        _marketPrice = price;
        _offsetProjects = projects['projects'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
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
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Carbon Credits (CCTS 2023) 🌍", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "My Wallet"),
            Tab(text: "Compliance"),
            Tab(text: "Offset Projects"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWalletTab(),
                _buildComplianceTab(),
                _buildOffsetTab(),
              ],
            ),
    );
  }

  Widget _buildWalletTab() {
    final balance = _walletData?['ccc_balance'] ?? 0.0;
    final price = _marketPrice?['price_per_tco2'] ?? 1500.0;
    final value = balance * price;
    final emissions = _walletData?['net_emissions_tco2'] ?? 2.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF11998e), Color(0xFF38ef7d)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
            ),
            child: Column(
              children: [
                const Text("Carbon Credit Balance", style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 10),
                Text("${balance.toStringAsFixed(2)} CCC", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                Text("₹${NumberFormat('#,##,###').format(value)} Market Value", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(icon: Icons.add_circle, label: "Earn", onTap: () {}),
                    _ActionButton(icon: Icons.shopping_cart, label: "Buy", onTap: () {}),
                    _ActionButton(icon: Icons.sell, label: "Sell", onTap: () {}),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Household Emissions
          const Text("Household Footprint 🏠", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Net Emissions", style: TextStyle(color: Colors.white70)),
                    Text("${emissions.toStringAsFixed(2)} tCO2e", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (emissions / 5.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(emissions < 2.5 ? Colors.green : Colors.orange),
                ),
                const SizedBox(height: 10),
                Text(
                  emissions < 2.5 ? "🌱 You are below India's average!" : "⚠️ You are above India's average.",
                  style: TextStyle(color: emissions < 2.5 ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Recommendations
          if (_walletData?['recommendations'] != null) ...[
            const Text("Recommendations 💡", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(_walletData!['recommendations'] as List).map((rec) => 
              Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.yellowAccent),
                  title: Text(rec, style: const TextStyle(color: Colors.white70)),
                ),
              )
            ).toList(),
          ]
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
