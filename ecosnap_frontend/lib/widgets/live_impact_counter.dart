import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// Live Carbon Impact Counter - Shows real-time community sustainability impact
/// This is the HERO element that impresses hackathon judges with measurable impact
class LiveImpactCounter extends StatefulWidget {
  const LiveImpactCounter({super.key});

  @override
  State<LiveImpactCounter> createState() => _LiveImpactCounterState();
}

class _LiveImpactCounterState extends State<LiveImpactCounter> with TickerProviderStateMixin {
  // Simulated live counters (in production, these come from WebSocket/backend)
  double _co2Saved = 12847.3;      // kg
  double _kwhSaved = 48320.0;      // kWh
  double _moneySaved = 487650.0;   // ₹
  int _activeUsers = 2341;
  int _scansToday = 847;
  int _treesEquivalent = 642;

  late Timer _updateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for the live indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate real-time updates every 2-5 seconds
    _startLiveUpdates();
  }

  void _startLiveUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          // Realistic increments
          _co2Saved += random.nextDouble() * 2.5;
          _kwhSaved += random.nextDouble() * 8;
          _moneySaved += random.nextDouble() * 150;
          _scansToday += random.nextInt(3);
          
          // Occasional user/tree updates
          if (random.nextInt(5) == 0) {
            _activeUsers += random.nextInt(2);
            _treesEquivalent = (_co2Saved / 20).floor(); // 1 tree ≈ 20kg CO2/year
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatNumber(double num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D1B2A).withOpacity(0.95),
            const Color(0xFF1B263B).withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with live indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Live pulse indicator
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.greenAccent.withOpacity(_pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(_pulseAnimation.value * 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "ECOSNAP COMMUNITY IMPACT",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 12, color: Colors.greenAccent.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        "$_activeUsers active",
                        style: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Stats Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(child: _buildStatCard(
                  icon: "💨",
                  value: _formatNumber(_co2Saved),
                  unit: "kg",
                  label: "CO₂ Saved",
                  color: Colors.tealAccent,
                )),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(
                  icon: "🌳",
                  value: _treesEquivalent.toString(),
                  unit: "",
                  label: "Trees Worth",
                  color: Colors.green,
                )),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(
                  icon: "💰",
                  value: "₹${_formatNumber(_moneySaved)}",
                  unit: "",
                  label: "Saved",
                  color: Colors.amber,
                )),
              ],
            ),
          ),
          
          // Bottom bar with secondary stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat("⚡", "${_formatNumber(_kwhSaved)} kWh", "Energy"),
                _buildVerticalDivider(),
                _buildMiniStat("📸", "$_scansToday", "Scans Today"),
                _buildVerticalDivider(),
                _buildMiniStat("🎯", "SDG 7,11,12,13", "UN Goals"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.1),
    );
  }
}

/// Compact version for smaller spaces
class MiniImpactBadge extends StatelessWidget {
  final double co2Saved;
  
  const MiniImpactBadge({super.key, this.co2Saved = 12.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.2), Colors.teal.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🌍", style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            "${co2Saved.toStringAsFixed(1)} kg CO₂ saved",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
