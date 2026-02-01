import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> questions = [];
  bool isLoading = true;
  late GoogleMapController mapController;
  Set<Circle> _circles = {};
  bool _showHeatmap = true;

  final LatLng _center = const LatLng(19.0760, 72.8777); // Mumbai Coordinates

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _buildHeatmap();
  }

  void _buildHeatmap() {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId("area_1"),
          center: const LatLng(19.0760, 72.8777),
          radius: 2000,
          fillColor: Colors.greenAccent.withOpacity(0.3),
          strokeWidth: 2,
          strokeColor: Colors.greenAccent,
        ),
        Circle(
          circleId: const CircleId("area_2"),
          center: const LatLng(19.1136, 72.8697),
          radius: 1500,
          fillColor: Colors.orangeAccent.withOpacity(0.3),
          strokeWidth: 2,
          strokeColor: Colors.orangeAccent,
        ),
        Circle(
          circleId: const CircleId("area_3"),
          center: const LatLng(19.0330, 72.8515),
          radius: 1800,
          fillColor: Colors.redAccent.withOpacity(0.3),
          strokeWidth: 2,
          strokeColor: Colors.redAccent,
        ),
      };
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/community/questions'));
      if (response.statusCode == 200) {
        setState(() {
          questions = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> postQuestion(String title, String content) async {
    // Dummy user data
    final body = {
      "user_id": "test_user_id",
      "user_name": "Eco User", 
      "title": title,
      "content": content,
      "category": "General",
      "city": "Mumbai"
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/community/questions'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        fetchQuestions();
      }
    } catch (e) {
      print("Error posting question: $e");
    }
  }

  void _showAddQuestionDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ask the Community"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Question Title"),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: "Details"),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                postQuestion(titleController.text, contentController.text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text("Post"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community Pulse"),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          IconButton(
            icon: Icon(_showHeatmap ? Icons.map : Icons.layers_clear, color: Colors.greenAccent),
            onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
            tooltip: "Toggle Heatmap",
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          )
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "LIVE PULSE", icon: Icon(Icons.bolt)),
            Tab(text: "BULK DEALS", icon: Icon(Icons.shopping_basket)),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: LIVE PULSE
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // ECO-PULSE TICKER
                    Container(
                      width: double.infinity,
                      height: 40,
                      color: Colors.black,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 100, // Infinite feel
                        itemBuilder: (context, index) {
                          final feed = [
                            "⚡ Rahul saved ₹500 on Electricity bill using solar advice",
                            "🌿 Priya planted 5 trees in Sector 4",
                            "♻️ Amit successfully recycled 12kg of e-waste",
                            "🏆 Neha reached 'Eco-Warrior' Level 5",
                            "🌞 Neighborhood Solar Collective: Sector 4 is now 100% solar!",
                            "🚲 Sameer switched to cycling for work commutes",
                            "🚿 Local Building: Water recycling plant installed!",
                          ];
                          return Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(feed[index % feed.length], style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                    
                    // COMMUNITY IMPACT STATS
                    Container(
                      height: 100, // Increased from 80 to prevent overflow
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [
                          _impactStat("TREES", "1,240", Icons.park, Colors.greenAccent),
                          _impactStat("CO2 SAVED", "12.5T", Icons.cloud_done, Colors.blueAccent),
                          _impactStat("SOLAR", "50+ kW", Icons.wb_sunny, Colors.orangeAccent),
                          _impactStat("RECYCLED", "800kg", Icons.recycling, Colors.purpleAccent),
                        ],
                      ),
                    ),
                    // Map View
                    Container(
                      height: 250,
                      width: double.infinity,
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _center,
                            zoom: 11.0,
                          ),
                          circles: _showHeatmap ? _circles : {},
                          markers: {
                            const Marker(
                              markerId: MarkerId('mumbai_marker'),
                              position: LatLng(19.0760, 72.8777),
                              infoWindow: InfoWindow(title: 'High Adoption Area'),
                            ),
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: questions.length,
                        itemBuilder: (ctx, index) {
                          final q = questions[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.greenAccent.withOpacity(0.2),
                                        child: const Icon(Icons.person, size: 20, color: Colors.greenAccent),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(q['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text("By ${q['user_name'] ?? 'Eco Hero'} • ${q['city'] ?? 'Mumbai'}", style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text(q['category'], style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(q['content'], style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _actionButton(Icons.thumb_up_outlined, "${q['upvotes'] ?? 0}", Colors.greenAccent),
                                      const SizedBox(width: 16),
                                      _actionButton(Icons.chat_bubble_outline, "${q['answer_count'] ?? 0} Answers", Colors.white60),
                                      const Spacer(),
                                      const Icon(Icons.share_outlined, size: 18, color: Colors.white38),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          
          // TAB 2: BULK DEALS (Merged from GroupBuyingHub)
          _buildBulkDealsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: const Icon(Icons.add),
        tooltip: "Ask Question",
      ),
    );
  }

  Widget _buildBulkDealsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDealCard("Solar Panel Kit 5kW", "Mumbai Neighborhood", "₹45,000", "30% OFF", 7, 10, Colors.orangeAccent),
        const SizedBox(height: 16),
        _buildDealCard("EV Home Charger", "Bandra West", "₹12,000", "15% OFF", 42, 50, Colors.blueAccent),
        const SizedBox(height: 16),
        _buildDealCard("Bamboo Furniture Set", "Powai", "₹8,500", "20% OFF", 12, 20, Colors.greenAccent),
      ],
    );
  }

  Widget _buildDealCard(String title, String location, String price, String discount, int current, int target, Color themeColor) {
    final progress = current / target;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(color: themeColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                 child: Text(discount, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12)),
               ),
               const Icon(Icons.timer_outlined, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Current: $current committed", style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text("Target: $target", style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.white10, color: themeColor),
          ),
          const SizedBox(height: 12),
          Text(price, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Commit to Buy", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _mapMarker() {
      return const Icon(Icons.location_on, color: Colors.redAccent, size: 40);
  }

  Widget _impactStat(String label, String value, IconData icon, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
