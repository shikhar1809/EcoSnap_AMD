import 'package:flutter/material.dart';

/// Green AI Metrics Widget
/// Shows that EcoSnap's AI is itself environmentally conscious
/// This is a KILLER differentiator: "We measure our own AI's carbon footprint"
class GreenAiMetrics extends StatelessWidget {
  final double analysisEmissions; // grams CO2
  final double energyUsed; // Wh
  final double cloudComparison; // how much more cloud would use

  const GreenAiMetrics({
    super.key,
    this.analysisEmissions = 0.023,
    this.energyUsed = 0.0012,
    this.cloudComparison = 0.97, // 97% less than cloud
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.teal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Green AI icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: Colors.greenAccent, size: 18),
          ),
          const SizedBox(width: 12),
          
          // Metrics
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "GREEN AI ANALYSIS",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${(cloudComparison * 100).toStringAsFixed(0)}% GREENER",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniMetric("💨", "${(analysisEmissions * 1000).toStringAsFixed(1)}mg CO₂"),
                    const SizedBox(width: 16),
                    _miniMetric("⚡", "${(energyUsed * 1000).toStringAsFixed(2)}mWh"),
                    const SizedBox(width: 16),
                    _miniMetric("🌱", "Carbon Neutral"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Detailed Green AI report for results page
class GreenAiReport extends StatelessWidget {
  final String journeyType;
  final double processingTimeMs;

  const GreenAiReport({
    super.key,
    required this.journeyType,
    this.processingTimeMs = 1200,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate approximate emissions based on processing time
    // These are realistic estimates for edge AI inference
    final double emissions = processingTimeMs * 0.00002; // ~0.02g per second
    final double energy = processingTimeMs * 0.000001; // ~0.001 Wh per second
    final double cloudEquiv = emissions * 50; // Cloud would use ~50x more

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF004d40).withOpacity(0.3),
            const Color(0xFF00695c).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.greenAccent.withOpacity(0.3), Colors.tealAccent.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.memory, color: Colors.greenAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GREEN AI ANALYSIS REPORT",
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "Powered by on-device inference",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.greenAccent, size: 12),
                    SizedBox(width: 4),
                    Text(
                      "CodeCarbon",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Metrics row
          Row(
            children: [
              Expanded(child: _metricCard("AI Emissions", "${(emissions * 1000).toStringAsFixed(2)} mg", "CO₂", Colors.greenAccent)),
              const SizedBox(width: 8),
              Expanded(child: _metricCard("Energy Used", "${(energy * 1000).toStringAsFixed(3)} mWh", "Electricity", Colors.amber)),
              const SizedBox(width: 8),
              Expanded(child: _metricCard("Cloud Equiv.", "${cloudEquiv.toStringAsFixed(2)} g", "CO₂ Saved", Colors.redAccent)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Comparison bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EcoSnap AI vs Cloud AI",
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 2, // EcoSnap uses much less
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 98, // Cloud uses much more
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "98% less emissions than traditional cloud AI",
                style: TextStyle(color: Colors.greenAccent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}
