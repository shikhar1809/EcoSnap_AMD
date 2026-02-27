import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/advanced_feature_service.dart';
class RyzenAiToggleWidget extends StatelessWidget {
  const RyzenAiToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final featureService = context.watch<AdvancedFeatureService>();
    final isEdgeEnabled = featureService.isEdgeModeEnabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEdgeEnabled ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isEdgeEnabled ? Colors.green.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.memory,
            size: 32,
            color: isEdgeEnabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AMD Ryzen™ AI Edge Processing',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isEdgeEnabled ? 'Active: Zero Cloud Dependency' : 'Disabled: Using Cloud APIs',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEdgeEnabled ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEdgeEnabled,
            activeColor: Colors.green,
            onChanged: (bool value) {
              context.read<AdvancedFeatureService>().toggleEdgeMode(value);
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
