import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// Impact Passport - Verifiable sustainability credentials
/// Shows user's verified impact with shareable certificate
/// This builds TRUST - key differentiator from greenwashing
class ImpactPassport extends StatelessWidget {
  final String userName;
  final double totalCo2Saved;
  final int scansCompleted;
  final int treesEquivalent;
  final String ecoLevel;
  final DateTime memberSince;
  final String verificationHash;
  final double carbonCreditsBalance; // NEW: Carbon Credits

  const ImpactPassport({
    super.key,
    required this.userName,
    required this.totalCo2Saved,
    required this.scansCompleted,
    required this.treesEquivalent,
    required this.ecoLevel,
    required this.memberSince,
    required this.verificationHash,
    this.carbonCreditsBalance = 0.0,
  });

  factory ImpactPassport.demo() {
    return ImpactPassport(
      userName: "Eco Warrior",
      totalCo2Saved: 127.5,
      scansCompleted: 42,
      treesEquivalent: 6,
      ecoLevel: "Climate Champion",
      memberSince: DateTime.now().subtract(const Duration(days: 45)),
      verificationHash: "0x${Random().nextInt(999999).toRadixString(16).padLeft(6, '0')}...${Random().nextInt(9999).toRadixString(16).padLeft(4, '0')}",
      carbonCreditsBalance: 12.50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 2,
          color: Colors.greenAccent.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.greenAccent.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.greenAccent.withOpacity(0.3), Colors.tealAccent.withOpacity(0.3)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.eco, color: Colors.greenAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ECOSNAP IMPACT PASSPORT",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildVerifiedBadge(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10), // Reduced padding for 4 items
            child: Row(
              children: [
                Expanded(child: _buildMainStat("🌍", "${totalCo2Saved.toStringAsFixed(1)}", "kg CO₂")),
                _buildDivider(),
                Expanded(child: _buildMainStat("🌳", "$treesEquivalent", "Trees")),
                _buildDivider(),
                Expanded(child: _buildMainStat("📸", "$scansCompleted", "Scans")),
                _buildDivider(),
                Expanded(child: _buildMainStat("☁️", "${carbonCreditsBalance.toStringAsFixed(2)}", "Credits")),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Level Badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.2),
                  Colors.orange.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🏆", style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ECO LEVEL",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      ecoLevel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SDG Contribution
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CONTRIBUTING TO UN SDGS",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSdgMini(7, "Energy", const Color(0xFFFCC30B)),
                    const SizedBox(width: 8),
                    _buildSdgMini(12, "Consumption", const Color(0xFFCF8D2A)),
                    const SizedBox(width: 8),
                    _buildSdgMini(13, "Climate", const Color(0xFF3F7E44)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Verification Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, size: 14, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 6),
                    Text(
                      "Blockchain Verified: $verificationHash",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.share,
                      "Share",
                      Colors.blueAccent,
                      () => _showShareOptions(context),
                    ),
                    _buildActionButton(
                      context,
                      Icons.download,
                      "Download",
                      Colors.greenAccent,
                      () => _downloadCertificate(context),
                    ),
                    _buildActionButton(
                      context,
                      Icons.qr_code,
                      "QR Verify",
                      Colors.purpleAccent,
                      () => _showQrCode(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.greenAccent, size: 14),
          SizedBox(width: 4),
          Text(
            "Verified",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildSdgMini(int num, String name, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  "$num",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📤 Share your Impact Passport on LinkedIn, Twitter, or Instagram!"),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _downloadCertificate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📥 Generating PDF Certificate..."),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  void _showQrCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.purpleAccent),
            SizedBox(width: 10),
            Text("Verification QR", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_2, size: 150, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Scan to verify this Impact Passport",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
            ),
            const SizedBox(height: 8),
            SelectableText(
              verificationHash,
              style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: verificationHash));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hash copied to clipboard!")),
              );
            },
            child: const Text("Copy Hash", style: TextStyle(color: Colors.purpleAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

/// Mini version for displaying in profile or results
class MiniImpactCard extends StatelessWidget {
  final double co2Saved;
  final int scans;
  
  const MiniImpactCard({super.key, required this.co2Saved, required this.scans});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.greenAccent.withOpacity(0.1), Colors.tealAccent.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat("🌍", "${co2Saved.toStringAsFixed(1)} kg", "CO₂ Saved"),
          Container(width: 1, height: 30, color: Colors.white10),
          _stat("📸", "$scans", "Scans"),
          Container(width: 1, height: 30, color: Colors.white10),
          _stat("✓", "Verified", "Blockchain"),
        ],
      ),
    );
  }

  Widget _stat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
      ],
    );
  }
}
