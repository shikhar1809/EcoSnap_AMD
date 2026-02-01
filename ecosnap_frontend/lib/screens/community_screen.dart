import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ecosnap_frontend/services/api_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  
  // Data
  List<dynamic> _feed = [];
  Map<String, dynamic> _insights = {};
  List<dynamic> _leaderboard = [];
  List<dynamic> _challenges = [];
  bool _isLoading = true;
  
  // Map
  late GoogleMapController mapController;
  final Set<Circle> _circles = {};
  bool _showHeatmap = true;
  final LatLng _center = const LatLng(19.0760, 72.8777); // Mumbai
  String _city = "Mumbai";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
    _buildHeatmap();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final feedRes = await _apiService.getCommunityFeed(_city);
      final insightsRes = await _apiService.getCommunityInsights(_city);
      final leaderboardRes = await _apiService.getCommunityLeaderboard(_city);
      // Challenges - mocking for now or fetching if endpoint exists (added to service)
      // We didn't add getChallenges to api_service explicitly in step 893, but logic exists in service
      // Let's assume we can fetch or mock challenges for now based on insights
      
      if (mounted) {
        setState(() {
          _feed = feedRes['feed'] ?? [];
          _insights = insightsRes;
          _leaderboard = leaderboardRes['leaderboard'] ?? [];
          _challenges = [
            {"title": "Solar Sprint", "target": "100 Homes", "current": 67, "desc": "Get your sector to 100% solar!"},
            {"title": "Zero Waste Week", "target": "1000 kg", "current": 450, "desc": "Recycle e-waste this week."},
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching community data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _buildHeatmap() {
    _circles.add(Circle(
        circleId: const CircleId("area_1"),
        center: const LatLng(19.0760, 72.8777),
        radius: 2000,
        fillColor: Colors.greenAccent.withOpacity(0.3),
        strokeWidth: 0));
    _circles.add(Circle(
        circleId: const CircleId("area_2"),
        center: const LatLng(19.1136, 72.8697),
        radius: 1500,
        fillColor: Colors.orangeAccent.withOpacity(0.3),
        strokeWidth: 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Community Pulse ⚡", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
             icon: const Icon(Icons.refresh, color: Colors.white70),
             onPressed: _fetchData,
          ), 
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelColor: Colors.greenAccent,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: "LIVE PULSE"),
            Tab(text: "LEADERBOARD"),
            Tab(text: "CHALLENGES"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPulseTab(),
                _buildLeaderboardTab(),
                _buildChallengesTab(),
              ],
            ),
    );
  }

  Widget _buildPulseTab() {
    // Top Impact Stats from Insights
    final impact = _insights;
    final totalCO2 = impact['total_co2_saved_kg'] ?? 0;
    
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        children: [
          // Ticker
          Container(
            height: 40,
            color: Colors.white10,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "🚀 TRENDING: ${impact['social_proof'] ?? 'Loading...'}  •  🔥 Top Action: ${impact['top_action']?['type'] ?? 'Solar'}",
              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Courier', fontWeight: FontWeight.bold),
            ),
          ),
          
          // Stats Row
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard("CO2 Saved", "${(totalCO2/1000).toStringAsFixed(1)}T", Icons.cloud_done, Colors.blue),
                _StatCard("Solar Homes", "41", Icons.solar_power, Colors.orange),
                _StatCard("Actions", impact['feed_count'].toString(), Icons.bolt, Colors.green),
              ],
            ),
          ),

          // Map
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
                circles: _showHeatmap ? _circles : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapStyle: '[{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},{"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},{"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},{"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},{"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},{"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},{"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},{"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},{"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},{"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},{"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},{"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},{"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},{"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}]',
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text("Live Activity Feed", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),

          // Feed List
          ..._feed.map((item) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white10,
                  backgroundImage: item['avatar_url'] != null ? NetworkImage(item['avatar_url']) : null,
                  child: item['avatar_url'] == null ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(text: TextSpan(
                        style: const TextStyle(color: Colors.white),
                        children: [
                          TextSpan(text: item['user_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: " ${item['description']}", style: const TextStyle(color: Colors.white70)),
                        ]
                      )),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.bolt, size: 14, color: Colors.yellowAccent),
                          Text(item['points_earned'].toString(), style: const TextStyle(color: Colors.yellowAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Icon(Icons.eco, size: 14, color: Colors.greenAccent),
                          Text("${item['co2_saved_kg']}kg CO2", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                          const Spacer(),
                          Text(item['timestamp'] ?? 'Just now', style: const TextStyle(color: Colors.white30, fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          )).toList()
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
     return ListView.separated(
       padding: const EdgeInsets.all(16),
       itemCount: _leaderboard.length,
       separatorBuilder: (_, __) => const SizedBox(height: 10),
       itemBuilder: (ctx, i) {
         final user = _leaderboard[i];
         final rank = user['rank'];
         final isTop3 = rank <= 3;
         
         return Container(
           decoration: BoxDecoration(
             color: isTop3 ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
             borderRadius: BorderRadius.circular(15),
             border: isTop3 ? Border.all(color: Colors.amber.withOpacity(0.5)) : null,
           ),
           child: ListTile(
             leading: CircleAvatar(
               backgroundColor: isTop3 ? Colors.amber : Colors.grey[800],
               child: Text("#$rank", style: TextStyle(color: isTop3 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
             ),
             title: Text(user['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             subtitle: Text(user['tier'], style: TextStyle(color: _getTierColor(user['tier']))),
             trailing: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Text("${user['points']} pts", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 if (user['badges'] != null && (user['badges'] as List).isNotEmpty)
                   const Icon(Icons.verified, size: 14, color: Colors.blueAccent)
               ],
             ),
           ),
         ).animate().slideX(delay: Duration(milliseconds: i * 50));
       },
     );
  }
  
  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _challenges.map((c) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c['title'], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Text("ACTIVE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(c['desc'], style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Progress: ${c['current']} / ${c['target']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${(c['current']/1000*100).toInt()}%", style: const TextStyle(color: Colors.white70)), // Dummy calc for display
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.6, // Dummy
              backgroundColor: Colors.black26,
              color: Colors.greenAccent,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                child: const Text("Join Challenge"),
              ),
            )
          ],
        ),
      )).toList(),
    );
  }

  Color _getTierColor(String tier) {
    if (tier.contains("Hero")) return Colors.purpleAccent;
    if (tier.contains("Champion")) return Colors.amber;
    if (tier.contains("Warrior")) return Colors.redAccent;
    return Colors.greenAccent;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
