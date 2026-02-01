import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class EcoRPGJourney extends StatefulWidget {
  final int currentLevel;
  final int ecoPoints;
  final Set<String> equippedGear;
  final bool isMale;

  const EcoRPGJourney({
    Key? key,
    required this.currentLevel,
    required this.ecoPoints,
    required this.equippedGear,
    required this.isMale,
  }) : super(key: key);

  @override
  State<EcoRPGJourney> createState() => _EcoRPGJourneyState();
}

class _EcoRPGJourneyState extends State<EcoRPGJourney> {
  // VIEW STATE: 'MAP' or 'COMBAT'
  String _viewState = "MAP"; 
  
  // COMBAT STATE
  String _combatStatus = "IDLE"; // IDLE, WALKING, FIGHTING, VICTORY, DEFEAT
  String _combatMessage = "";
  int _selectedLevelIndex = 0;

  // LEVEL DATA
  final List<Map<String, dynamic>> _levels = [
    {
      "id": 1,
      "name": "Dusty Outskirts",
      "boss": "Dust Mite Titan",
      "boss_icon": Icons.bug_report,
      "boss_color": Colors.brown,
      "min_xp": 0, // Tutorial level
      "desc": "A smog-filled wasteland. Easy for a rookie.",
      "weakness": "Basic Mask"
    },
    {
      "id": 2,
      "name": "Smog City",
      "boss": "CO2 Golem",
      "boss_icon": Icons.cloud_off,
      "boss_color": Colors.grey,
      "min_xp": 500, // Needs some grinding/gear
      "desc": "Thick pollution. You need a Gas Mask!",
      "weakness": "Gas Mask"
    },
    {
      "id": 3,
      "name": "Toxic Dump",
      "boss": "Sludge Monster",
      "boss_icon": Icons.coronavirus,
      "boss_color": Colors.green,
      "min_xp": 1500, // Needs armors
      "desc": "Radioactive waste. Hazmat Suit required.",
      "weakness": "Hazmat Suit"
    },
    {
      "id": 4,
      "name": "Inferno Core",
      "boss": "Heatwave Dragon",
      "boss_icon": Icons.local_fire_department,
      "boss_color": Colors.orange,
      "min_xp": 3000, // End game
      "desc": "Global Warming incarnate. Ice Shield needed.",
      "weakness": "Ice Shield"
    },
  ];

  void _enterLevel(int index) {
    if (widget.ecoPoints < _levels[index]['min_xp']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Locked! Need ${_levels[index]['min_xp']} XP to enter."), backgroundColor: Colors.red)
      );
      return;
    }
    
    setState(() {
      _selectedLevelIndex = index;
      _viewState = "COMBAT";
      _combatStatus = "WALKING";
      _combatMessage = "Approaching ${_levels[index]['name']}...";
    });

    _runCombatSequence();
  }

  void _runCombatSequence() async {
    // 1. Walking Phase
    await Future.delayed(2.seconds);

    if (!mounted) return;
    setState(() {
      _combatStatus = "FIGHTING";
      _combatMessage = "BOSS FIGHT: ${_levels[_selectedLevelIndex]['boss']}!";
    });

    // 2. Fighting Phase
    await Future.delayed(2.5.seconds);

    if (!mounted) return;
    _calculateOutcome();
  }

  void _calculateOutcome() {
    final level = _levels[_selectedLevelIndex];
    // Win Condition: 
    // 1. Must have XP >= Level requirement (already checked at partial entry, but double check)
    // 2. Bonus: If have specific gear, instant win. Otherwise, roll dice based on total gear count.

    bool hasWeaknessGear = widget.equippedGear.any((g) => g.contains(level['weakness'])); // Simple string match
    int power = widget.equippedGear.length * 100 + (widget.ecoPoints ~/ 10);
    int difficulty = (level['id'] as int) * 300; 

    // For demo: If you have enough XP to enter, you implicitly have a chance, 
    // but without gear it's a 50/50. With gear it's 100%.
    bool victory = hasWeaknessGear || (power > difficulty);

    setState(() {
      _combatStatus = victory ? "VICTORY" : "DEFEAT";
      _combatMessage = victory 
        ? "Victory! You cleansed the area." 
        : "Defeat! Upgrade your gear.";
    });
  }

  void _returnToMap() {
    setState(() {
      _viewState = "MAP";
      _combatStatus = "IDLE";
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 500.ms,
      height: 380, // Slightly taller for map
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        image: DecorationImage(
          image: const NetworkImage("https://images.unsplash.com/photo-1542831371-29b0f74f9713?q=80&w=1000&auto=format&fit=crop"), // Dark abstract bg
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken),
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: _viewState == "MAP" ? _buildLevelMap() : _buildCombatView(),
    );
  }

  Widget _buildLevelMap() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CAMPAIGN MAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.stars, size: 16, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text("${widget.ecoPoints} XP", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
                ]),
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal, // Horizontal scroll feels more like a "Journey" left-to-right
            itemCount: _levels.length,
            itemBuilder: (context, index) {
              final level = _levels[index];
              final isLocked = widget.ecoPoints < level['min_xp'];
              final isCompleted = widget.currentLevel > index; // Assuming simple linear progression for display

              return _buildLevelNode(level, index, isLocked, isCompleted);
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text("Scroll to explore sectors", style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLevelNode(Map<String, dynamic> level, int index, bool isLocked, bool isCompleted) {
    return GestureDetector(
      onTap: () => _enterLevel(index),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // NODE ICON
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked ? Colors.grey.withOpacity(0.2) : level['boss_color'].withOpacity(0.2),
                border: Border.all(
                  color: isLocked ? Colors.grey : (isCompleted ? Colors.greenAccent : level['boss_color']),
                  width: isCompleted ? 3 : 1
                ),
                boxShadow: isLocked ? [] : [
                  BoxShadow(color: level['boss_color'].withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                ]
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isLocked ? Icons.lock : level['boss_icon'],
                    color: isLocked ? Colors.white38 : Colors.white,
                    size: 30
                  ),
                  if (isCompleted)
                    const Positioned(bottom: 0, right: 0, child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 24))
                ],
              ),
            ).animate(target: isLocked ? 0 : 1).scale(curve: Curves.easeOutBack),
            
            // CONNECTOR LINE (Visual only, to next node)
            // In a real map this would connect nodes, but in horizontal list, implied.
            
            const SizedBox(height: 16),
            
            // TEXT INFO
            Text(
              "LEVEL ${level['id']}",
              style: TextStyle(color: isLocked ? Colors.grey : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 4),
            Text(
              level['name'],
              style: TextStyle(color: isLocked ? Colors.grey : Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (isLocked)
              Text("Need ${level['min_xp']} XP", style: const TextStyle(color: Colors.redAccent, fontSize: 10))
            else
              Text("Boss: ${level['boss']}", style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildCombatView() {
    final level = _levels[_selectedLevelIndex];
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // BACKGROUND 
        Positioned.fill(
          child: Container(
             color: Colors.black.withOpacity(0.6), // Dim the bg image
          ),
        ),

        // TOP HUD
        Positioned(
          top: 20,
          left: 20,
          child: Row(
            children: [
              IconButton(onPressed: _returnToMap, icon: const Icon(Icons.arrow_back, color: Colors.white)),
              const SizedBox(width: 8),
              Text(level['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
            ],
          )
        ),

        // WARRIOR
        AnimatedPositioned(
          duration: 1.seconds,
          curve: Curves.easeInOut,
          left: _combatStatus == "WALKING" ? 50 : 80,
          bottom: 80,
          child: _buildWarriorAvatar(),
        ),

        // BOSS
        if (_combatStatus != "WALKING")
          Positioned(
            right: 50,
            bottom: 80, 
            child: _buildBossAvatar(level),
          ),

        // STATUS TEXT
        Positioned(
          top: 80,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
            child: Text(_combatMessage, style: TextStyle(color: _combatStatus == "DEFEAT" ? Colors.red : Colors.yellowAccent, fontWeight: FontWeight.bold)),
          ).animate().fadeIn().slideY(begin: -0.5, end: 0),
        ),

        // ACTION BUTTONS (Result)
        if (_combatStatus == "VICTORY" || _combatStatus == "DEFEAT")
          Positioned(
            bottom: 150,
            child: ElevatedButton(
              onPressed: _returnToMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _combatStatus == "VICTORY" ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
              ),
              child: Text(_combatStatus == "VICTORY" ? "CLAIM REWARD & RETURN" : "RETREAT & UPGRADE"),
            ).animate().scale(curve: Curves.elasticOut),
          )
      ],
    );
  }

  Widget _buildWarriorAvatar() {
    // Mini version of the 3D warrior or just an icon for this view
    Widget avatar = Icon(widget.isMale ? Icons.man : Icons.woman, size: 80, color: Colors.white);
    
    if (_combatStatus == "FIGHTING") {
      avatar = avatar.animate(onPlay: (c) => c.repeat()).shake(duration: 200.ms).tint(color: Colors.red, duration: 200.ms);
    }
    
    return Column(
      children: [
        Container(width: 50, height: 5, color: Colors.green, margin: const EdgeInsets.only(bottom: 5)),
        avatar,
      ],
    );
  }

  Widget _buildBossAvatar(Map<String, dynamic> level) {
    Widget boss = Icon(level['boss_icon'], size: 100, color: level['boss_color']);
    
    if (_combatStatus == "FIGHTING") {
      boss = boss.animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2));
    } else if (_combatStatus == "VICTORY") {
      boss = boss.animate().fadeOut(duration: 500.ms).scale(end: const Offset(0, 0));
    }
    
    return Column(
      children: [
        Container(width: 80, height: 5, color: Colors.red, margin: const EdgeInsets.only(bottom: 5)),
        boss,
        Text(level['boss'], style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
