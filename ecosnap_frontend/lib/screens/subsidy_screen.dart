import 'package:flutter/material.dart';
import 'package:ecosnap_frontend/services/api_service.dart';
import 'package:intl/intl.dart';

class SubsidyScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const SubsidyScreen({Key? key, this.initialData}) : super(key: key);

  @override
  _SubsidyScreenState createState() => _SubsidyScreenState();
}

class _SubsidyScreenState extends State<SubsidyScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  // Data
  Map<String, dynamic> _allSchemes = {};
  Map<String, dynamic> _coverageStats = {};
  List<dynamic> _trendingSchemes = [];
  bool _isLoading = true;
  String _selectedState = "All";
  
  // Recommender Form
  String _recState = "Maharashtra";
  String _recAction = "solar";
  String _recIncome = "< 10L";
  final TextEditingController _capacityController = TextEditingController(text: "3");
  Map<String, dynamic>? _recommendationResult;

  final List<String> _states = [
    "All", "Maharashtra", "Karnataka", "Gujarat", "Delhi", "Tamil Nadu", "Rajasthan", "Uttar Pradesh"
  ];
  
  final List<String> _actions = ["solar", "ev", "energy_efficiency"];
  final List<String> _incomeBrackets = ["< 10L", "10-20L", "> 20L"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Auto-fill from AI data if present
    if (widget.initialData != null) {
      final journey = widget.initialData!['journey'];
      if (journey == 'SOLAR_AUDIT') {
        _recAction = 'solar';
        final solar = widget.initialData!['solar_potential'] ?? {};
        _capacityController.text = (solar['recommended_capacity_kw'] ?? 3).toString();
      } else if (journey == 'ROOM_ENERGY') {
        _recAction = 'energy_efficiency';
      }
      
      // Auto-trigger recommendation if we have enough data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getRecommendations();
        _tabController.animateTo(1); // Switch to eligibility tab
      });
    }
    
    _fetchSchemes();
  }

  Future<void> _fetchSchemes() async {
    setState(() => _isLoading = true);
    try {
      // Parallel fetch
      final results = await Future.wait([
        _apiService.getSubsidyCoverage(),
        _apiService.getTrendingSubsidies("Maharashtra") // Default for trending
      ]);
      
      if (results[0] != null) {
        _coverageStats = Map<String, dynamic>.from(results[0] as Map);
      }
      _trendingSchemes = results[1] as List<dynamic>;
      
      setState(() => _isLoading = false);
    } catch (e) {
      print("Error fetching subsidies: $e");
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _getRecommendations() async {
    try {
      final res = await _apiService.recommendSubsidies(
        _recState, 
        _recAction, 
        capacityKw: double.tryParse(_capacityController.text) ?? 2.5,
        incomeBracket: _recIncome
      );
      setState(() => _recommendationResult = res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _apply(String schemeId, String name) async {
    // Show static application success for demo
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("Application Submitted 📝", style: TextStyle(color: Colors.greenAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 15),
            Text("You have applied for $name", style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Your application ID: APP-2026-X9Y2", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: Colors.greenAccent)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Subsidy Database 💰", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "Exploer"),
            Tab(text: "Check Eligibility"),
            Tab(text: "Tracker"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSchemesTab(),
                _buildRecommenderTab(),
                _buildTrackerTab(),
              ],
            ),
    );
  }

  Widget _buildSchemesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trending Section
          if (_trendingSchemes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
              child: Row(
                children: const [
                  Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text("Trending in Your Area", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(
              height: 140, // Height for horizontal cards
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _trendingSchemes.length,
                itemBuilder: (ctx, i) {
                  final s = _trendingSchemes[i];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.purpleAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.2)]),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12)
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s['name'] ?? "Scheme", maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text("${s['users_applied'] ?? '2k+'} Applied", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                             const SizedBox(height: 5),
                             ElevatedButton(
                               onPressed: () => _apply("TREND_$i", s['name']),
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.white,
                                 foregroundColor: Colors.black,
                                 minimumSize: const Size(double.infinity, 30),
                                 padding: EdgeInsets.zero
                               ),
                               child: const Text("Apply Found"),
                             )
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          
          const Divider(color: Colors.white12, thickness: 1),
          
          // Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text("Filter by State:", style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedState,
                    dropdownColor: const Color(0xFF1A1A2E),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    underline: Container(height: 1, color: Colors.amber),
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _selectedState = v!),
                  ),
                )
              ],
            ),
          ),
          
          // List
          ListView.builder(
            shrinkWrap: true, // Needed inside ScrollView
            physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
            padding: const EdgeInsets.all(16),
            itemCount: 6, // Demo limit
            itemBuilder: (ctx, i) {
              final schemes = [
                {"name": "PM Surya Ghar", "type": "Central", "amount": "₹78,000", "state": "All"},
                {"name": "FAME II EV Subsidy", "type": "Central", "amount": "₹1.5 Lakh", "state": "All"},
                {"name": "MSEDCL Net Metering", "type": "State", "amount": "₹3.5/unit", "state": "Maharashtra"},
                {"name": "Delhi EV Policy", "type": "State", "amount": "₹1.5 Lakh", "state": "Delhi"},
                {"name": "Karnataka Solar Policy", "type": "State", "amount": "₹20,000", "state": "Karnataka"},
                {"name": "Gujarat Solar Rooftop", "type": "State", "amount": "₹15,000", "state": "Gujarat"},
              ].where((s) => _selectedState == "All" || s['state'] == _selectedState || s['type'] == "Central").toList();
              
              if (i >= schemes.length) return const SizedBox.shrink();
              final s = schemes[i];
              
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  title: Text(s['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("${s['type']} Government Scheme", style: const TextStyle(color: Colors.white54)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(s['amount']!, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 5),
                      const Icon(Icons.arrow_forward, color: Colors.white30, size: 16)
                    ],
                  ),
                  onTap: () => _apply("SCHEME_$i", s['name']!),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRecommenderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Smart Eligibility Checker 🤖", style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Answer 3 questions to check instant eligibility.", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<String>(
            value: _recState,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("State"),
            items: _states.where((s) => s != "All").map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _recState = v!),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _recAction,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Planned Action"),
            items: _actions.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _recAction = v!),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _recIncome,
            dropdownColor: const Color(0xFF1A1A2E),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Annual Income"),
            items: _incomeBrackets.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
            onChanged: (v) => setState(() => _recIncome = v!),
          ),
          
          if (_recAction == "solar") ...[
            const SizedBox(height: 15),
             TextField(
              controller: _capacityController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration("System Capacity (kW)"),
            ),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Check Eligibility", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 30),
          
          // Result
          if (_recommendationResult != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.shade900, Colors.amber.shade700]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 15)]
              ),
              child: Column(
                children: [
                  // Eligibility Badge
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 5),
                        Text("You are Eligible!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      ]
                    ),
                  ),
                  const Text("Total Potential Subsidy", style: TextStyle(color: Colors.white70)),
                  Text("₹${NumberFormat('#,##,###').format(_recommendationResult!['total_subsidy'])}", 
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white24, height: 30),
                  _DataRow("Central Subsidy", "₹${NumberFormat('#,##,###').format(_recommendationResult!['central_subsidy'])}"),
                  _DataRow("State Subsidy", "₹${NumberFormat('#,##,###').format(_recommendationResult!['state_subsidy'])}"),
                  const SizedBox(height: 15),
                  Text("Est. Approval: ${_recommendationResult!['estimated_approval_time']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Application Steps:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...(_recommendationResult!['application_steps'] as List).map((step) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.amber, size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step, style: const TextStyle(color: Colors.white70))),
                  ],
                ),
              )
            ).toList(),
             const SizedBox(height: 20),
             ElevatedButton(
               onPressed: () => _apply("COMBO", "Combined Schemes"),
               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
               child: const Text("Start Application Now"),
             )
          ]
        ],
      ),
    );
  }

  Widget _buildTrackerTab() {
    // Mock applications
    final apps = [
      {"name": "PM Surya Ghar", "id": "APP-9982", "status": "Under Review", "date": "2 Days Ago"},
      {"name": "MSEDCL Net Metering", "id": "APP-4551", "status": "Approved", "date": "1 Week Ago"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (ctx, i) {
        final app = apps[i];
        final isApproved = app['status'] == "Approved";
        
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(app['status']!, style: TextStyle(color: isApproved ? Colors.green : Colors.orange)),
                      backgroundColor: (isApproved ? Colors.green : Colors.orange).withOpacity(0.1),
                      side: BorderSide.none,
                    ),
                    Text(app['date']!, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(app['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("ID: ${app['id']}", style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 20),
                // Timeline
                Row(
                  children: [
                    _TimelineDot(active: true, first: true),
                    _TimelineLine(active: true),
                    _TimelineDot(active: true),
                    _TimelineLine(active: isApproved),
                    _TimelineDot(active: isApproved, last: true),
                  ],
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Applied", style: TextStyle(color: Colors.white30, fontSize: 10)),
                    Text("Review", style: TextStyle(color: Colors.white30, fontSize: 10)),
                    Text("Approved", style: TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  const _DataRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final bool active;
  final bool first;
  final bool last;
  const _TimelineDot({this.active = false, this.first = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12, height: 12,
      decoration: BoxDecoration(
        color: active ? Colors.amber : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TimelineLine extends StatelessWidget {
  final bool active;
  const _TimelineLine({this.active = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Colors.amber : Colors.grey,
      ),
    );
  }
}
