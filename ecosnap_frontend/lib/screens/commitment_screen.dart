import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'warrior_3d_screen.dart';
import '../widgets/level_map_widget.dart';

class CommitmentScreen extends StatefulWidget {
  const CommitmentScreen({Key? key}) : super(key: key);

  @override
  _CommitmentScreenState createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> {
  int ecoPoints = 2500; // Demo points
  Set<String> ownedGear = {'Basic Cloak'};
  String? equippedHelmet;
  String? equippedArmor;
  String? equippedShield;
  bool isMale = true; // Default gender

  final List<Map<String, dynamic>> shopItems = [
    {
      'name': 'Forest Helmet',
      'type': 'helmet',
      'cost': 500,
      'icon': Icons.shield_moon,
      'color': Colors.greenAccent
    },
    {
      'name': 'Solar Armor',
      'type': 'armor',
      'cost': 1200,
      'icon': Icons.wb_sunny,
      'color': Colors.orangeAccent
    },
    {
      'name': 'Recycle Shield',
      'type': 'shield',
      'cost': 800,
      'icon': Icons.recycling,
      'color': Colors.blueAccent
    },
    {
      'name': 'Guardian Wings',
      'type': 'armor',
      'cost': 2000,
      'icon': Icons.flight,
      'color': Colors.purpleAccent
    },
    {
      'name': 'Ocean Helmet',
      'type': 'helmet',
      'cost': 600,
      'icon': Icons.water_drop,
      'color': Colors.cyanAccent
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ecoPoints = prefs.getInt('eco_points') ?? 2500;
      ownedGear = (prefs.getStringList('owned_gear') ?? ['Basic Cloak']).toSet();
      equippedHelmet = prefs.getString('equipped_helmet');
      equippedArmor = prefs.getString('equipped_armor');
      equippedShield = prefs.getString('equipped_shield');
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('eco_points', ecoPoints);
    await prefs.setStringList('owned_gear', ownedGear.toList());
    if (equippedHelmet != null) await prefs.setString('equipped_helmet', equippedHelmet!);
    if (equippedArmor != null) await prefs.setString('equipped_armor', equippedArmor!);
    if (equippedShield != null) await prefs.setString('equipped_shield', equippedShield!);
  }

  void _buyItem(Map<String, dynamic> item) {
    if (ecoPoints >= item['cost'] && !ownedGear.contains(item['name'])) {
      setState(() {
        ecoPoints -= (item['cost'] as int);
        ownedGear.add(item['name']);
      });
      _saveProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unlocked ${item['name']}! 🛡️")),
      );
    } else if (ecoPoints < item['cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Not enough EcoPoints! Go scan more items! 🌿")),
      );
    }
  }

  void _equipItem(Map<String, dynamic> item) {
    setState(() {
      if (item['type'] == 'helmet') equippedHelmet = item['name'];
      if (item['type'] == 'armor') equippedArmor = item['name'];
      if (item['type'] == 'shield') equippedShield = item['name'];
    });
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.handshake, color: Colors.yellow),
            SizedBox(width: 8),
            Flexible(child: Text("Eco-Warrior Commitment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 4),
                  Text("$ecoPoints", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.greenAccent),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          )
        ],
      ),
      body: Column(
        children: [
          // LEVEL MAP AREA
          Expanded(
            child: LevelMapWidget(
              currentLevel: ecoPoints ~/ 500, // 500 points per level for demo
              starsPerLevel: {
                1: 3, 
                2: 3, 
                3: 2, 
                4: (ecoPoints >= 2000) ? 1 : 0
              }, // Demo data
              onLevelTap: _handleLevelTap,
            ),
          ),

          // SHOP SHORTCUT / CUSTOMIZE
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: Colors.black54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => Warrior3DScreen(
                         isMale: isMale,
                         equippedHelmet: equippedHelmet,
                         equippedArmor: equippedArmor,
                         equippedShield: equippedShield,
                         onGenderChanged: (val) {
                           setState(() => isMale = val);
                         },
                       )));
                    },
                    icon: const Icon(Icons.settings_accessibility, color: Colors.greenAccent, size: 20),
                    label: const Text("3D WARRIOR", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Quick shop view or scroll down
                      showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => _buildShopSheet());
                    }, 
                    icon: const Icon(Icons.shopping_bag, size: 20),
                    label: const Text("GEAR SHOP", style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.symmetric(horizontal: 8)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLevelTap(int levelId) {
    // Show commitment dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Level $levelId Challenge", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, size: 60, color: Colors.greenAccent),
            const SizedBox(height: 16),
            const Text(
              "Complete this eco-challenge to earn stars!", 
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Example challenge text hardcoded for demo
            Text(
              _getChallengeText(levelId),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("LATER")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simulating completion
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Challenge Accepted! 🌿")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("START"),
          )
        ],
      ),
    );
  }

  String _getChallengeText(int level) {
    switch(level) {
      case 1: return "Use no plastic bags for 24 hours.";
      case 2: return "Eat a fully vegetarian meal.";
      case 3: return "Walk or cycle instead of driving.";
      case 4: return "Unplug all unused electronics tonight.";
      case 5: return "Plant a restricted tree or plant.";
      default: return "Mystery Challenge!";
    }
  }

  Widget _buildShopSheet() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, color: Colors.white24),
          const SizedBox(height: 20),
          const Text("ECO GEAR SHOP", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: shopItems.length,
              itemBuilder: (context, index) {
                final item = shopItems[index];
                final isOwned = ownedGear.contains(item['name']);
                final isEquipped = equippedHelmet == item['name'] || equippedArmor == item['name'] || equippedShield == item['name'];
                
                return ListTile(
                  leading: Icon(item['icon'], color: item['color']),
                  title: Text(item['name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text("${item['cost']} XP", style: const TextStyle(color: Colors.white54)),
                  trailing: isOwned 
                    ? (isEquipped 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : ElevatedButton(onPressed: () { _equipItem(item); Navigator.pop(context); }, child: const Text("Equip")))
                    : ElevatedButton(onPressed: () { _buyItem(item); Navigator.pop(context); }, child: const Text("Buy")),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
