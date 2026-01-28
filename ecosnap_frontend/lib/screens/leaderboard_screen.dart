import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final users = await _apiService.getLeaderboard();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eco Champions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Column(
              children: [
                // Top Prize Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10)]
                  ),
                  child: const Column(
                    children: [
                       Text("🏆 Monthly Prize 🏆", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       SizedBox(height: 5),
                       Text("₹5,000", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                       Text("For the top saver this month!", style: TextStyle(color: Colors.white70)),
                    ]
                  ),
                ).animate().slideY(begin: -0.2, end: 0, duration: 600.ms),

                // Personal Progress (Mocked for MVP)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       const Column(children: [Text("Your Streak", style: TextStyle(color: Colors.grey)), SizedBox(height: 4), Row(children: [Icon(Icons.local_fire_department, color: Colors.orange), Text(" 3 Days", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])]),
                       const Column(children: [Text("This Month", style: TextStyle(color: Colors.grey)), SizedBox(height: 4), Text("+150 pts", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))]),
                    ],
                  ),
                ).animate().slideY(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms),

                // Govt Certification Badge
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.tealAccent.withOpacity(0.3))
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/images/logo.png', height: 50), // Fallback or badge icon
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Green Certificate", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("Tier 1: Green Starter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("Govt. of India Recognized", style: TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.verified, color: Colors.tealAccent, size: 30)
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isTop3 = index < 3;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isTop3 ? Colors.amber : Colors.grey.shade800,
                          child: Text("${index + 1}", style: TextStyle(color: isTop3 ? Colors.black : Colors.white)),
                        ),
                        title: Text(user['name'] ?? 'Anonymous', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(user['city'] ?? 'India', style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (user['streak_days'] != null && user['streak_days'] > 0)
                              Row(children: [Text("${user['streak_days']}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)), const Icon(Icons.local_fire_department, color: Colors.orange, size: 16), const SizedBox(width: 8)]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text("${user['points']} pts", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
