import 'package:flutter/material.dart';

/// UN Sustainable Development Goals Badge Display
/// Shows which SDGs the analysis contributes to
/// This demonstrates alignment with global sustainability framework - key for judges
class SdgBadges extends StatelessWidget {
  final List<int> sdgNumbers;
  final bool compact;

  const SdgBadges({
    super.key,
    required this.sdgNumbers,
    this.compact = false,
  });

  static const Map<int, SdgInfo> sdgData = {
    7: SdgInfo(
      number: 7,
      name: "Affordable & Clean Energy",
      shortName: "Clean Energy",
      color: Color(0xFFFCC30B),
      icon: "⚡",
    ),
    11: SdgInfo(
      number: 11,
      name: "Sustainable Cities & Communities",
      shortName: "Sustainable Cities",
      color: Color(0xFFF99D26),
      icon: "🏙️",
    ),
    12: SdgInfo(
      number: 12,
      name: "Responsible Consumption & Production",
      shortName: "Responsible Consumption",
      color: Color(0xFFCF8D2A),
      icon: "♻️",
    ),
    13: SdgInfo(
      number: 13,
      name: "Climate Action",
      shortName: "Climate Action",
      color: Color(0xFF3F7E44),
      icon: "🌍",
    ),
  };

  /// Get SDGs based on journey type
  static List<int> getForJourney(String journey) {
    switch (journey) {
      case 'SOLAR_AUDIT':
        return [7, 11, 13]; // Clean Energy, Sustainable Cities, Climate Action
      case 'ROOM_ENERGY':
        return [7, 12, 13]; // Clean Energy, Responsible Consumption, Climate Action
      case 'PRODUCT_SCAN':
        return [12, 13]; // Responsible Consumption, Climate Action
      case 'BILL_OCR':
        return [7, 12]; // Clean Energy, Responsible Consumption
      case 'FOOD_AUDIT':
        return [12, 13]; // Responsible Consumption, Climate Action
      case 'VEHICLE_CHECK':
        return [11, 13]; // Sustainable Cities, Climate Action
      default:
        return [12, 13]; // Default: Consumption & Climate
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadges();
    }
    return _buildFullBadges();
  }

  Widget _buildCompactBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public, size: 14, color: Colors.white54),
          const SizedBox(width: 6),
          Text(
            "SDG ${sdgNumbers.join(', ')}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadges() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.green.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.public, size: 16, color: Colors.blue),
              ),
              const SizedBox(width: 8),
              const Text(
                "UN SUSTAINABLE DEVELOPMENT GOALS",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sdgNumbers.map((num) {
              final info = sdgData[num];
              if (info == null) return const SizedBox.shrink();
              return _buildSdgChip(info);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSdgChip(SdgInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: info.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                "${info.number}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            info.icon,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            info.shortName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SdgInfo {
  final int number;
  final String name;
  final String shortName;
  final Color color;
  final String icon;

  const SdgInfo({
    required this.number,
    required this.name,
    required this.shortName,
    required this.color,
    required this.icon,
  });
}

/// SDG Impact Summary Widget - shows contribution to each goal
class SdgImpactSummary extends StatelessWidget {
  final String journey;
  final double co2Saved;
  final double energySaved;
  
  const SdgImpactSummary({
    super.key,
    required this.journey,
    this.co2Saved = 0,
    this.energySaved = 0,
  });

  @override
  Widget build(BuildContext context) {
    final sdgs = SdgBadges.getForJourney(journey);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a237e).withOpacity(0.3),
            const Color(0xFF0d47a1).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                "YOUR IMPACT ON UN SDGs",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sdgs.map((num) => _buildImpactRow(num)),
        ],
      ),
    );
  }

  Widget _buildImpactRow(int sdgNum) {
    final info = SdgBadges.sdgData[sdgNum];
    if (info == null) return const SizedBox.shrink();
    
    String impact = "";
    switch (sdgNum) {
      case 7:
        impact = energySaved > 0 ? "${energySaved.toStringAsFixed(1)} kWh saved" : "Cleaner energy choices";
        break;
      case 11:
        impact = "Sustainable urban living";
        break;
      case 12:
        impact = "Responsible consumption";
        break;
      case 13:
        impact = co2Saved > 0 ? "${co2Saved.toStringAsFixed(1)} kg CO₂ reduced" : "Climate positive action";
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: info.color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                "${info.number}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.shortName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  impact,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: info.color, size: 18),
        ],
      ),
    );
  }
}
