import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  bool _isNeighborhood = false;
  String _userPincode = "400050";
  String _userCity = "Mumbai";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final users = await _apiService.getLeaderboard();

    if (mounted) {
      setState(() {
        _users = users;
        _userPincode = prefs.getString('user_pincode') ?? "400050";
        _userCity = prefs.getString('user_city') ?? "Mumbai";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Champions",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent))
          : Column(
              children: [
                // Toggle Button
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(25)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleLoginOption("Global", !_isNeighborhood),
                      _toggleLoginOption("Neighborhood", _isNeighborhood),
                    ],
                  ),
                ),

                if (_isNeighborhood) ...[
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.purple.withOpacity(0.5),
                          Colors.blue.withOpacity(0.5)
                        ]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purpleAccent)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white),
                            const SizedBox(width: 8),
                            Text("PIN: $_userPincode",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text("Battle Active ⚔️",
                              style: TextStyle(
                                  color: Colors.yellowAccent,
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ).animate().shimmer(duration: const Duration(seconds: 2)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Top eco-finders in your neighborhood",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],

                // Plant Growth Tracker
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3))),
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 60,
                        width: 60,
                        child: Icon(Icons.local_florist,
                            size: 40,
                            color: Colors
                                .greenAccent), // Placeholder for plant image
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("My Eco Plant 🌱",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const LinearProgressIndicator(
                                value: 0.7,
                                backgroundColor: Colors.white10,
                                color: Colors.greenAccent,
                                minHeight: 8),
                          ),
                          const SizedBox(height: 4),
                          const Text("Details: 7 days streak to unlock Badge",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                        ],
                      ))
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isTop3 = index < 3;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isTop3 ? Colors.amber : Colors.grey.shade800,
                          child: Text("${index + 1}",
                              style: TextStyle(
                                  color: isTop3 ? Colors.black : Colors.white)),
                        ),
                        title: Text(user['name'] ?? 'Anonymous',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            _isNeighborhood
                                ? "Same Building"
                                : (user['city'] ?? 'India'),
                            style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (user['streak_days'] != null &&
                                user['streak_days'] > 0)
                              Row(children: [
                                Text("${user['streak_days']}",
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                                const Icon(Icons.local_fire_department,
                                    color: Colors.orange, size: 16),
                                const SizedBox(width: 8)
                              ]),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text("${user['points']} pts",
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (index * 100).ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toggleLoginOption(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isNeighborhood = (title == "Neighborhood");
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? Colors.greenAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
