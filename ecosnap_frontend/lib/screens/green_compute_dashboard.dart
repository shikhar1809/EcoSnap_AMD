import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/advanced_feature_service.dart';
class GreenComputeDashboard extends StatefulWidget {
  const GreenComputeDashboard({super.key});

  @override
  State<GreenComputeDashboard> createState() => _GreenComputeDashboardState();
}

class _GreenComputeDashboardState extends State<GreenComputeDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final isEdgeEnabled = context.read<AdvancedFeatureService>().isEdgeModeEnabled;
      final stats = await context.read<AdvancedFeatureService>().getAiComputeStats(isEdgeEnabled);
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load stats';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text(_error, style: const TextStyle(color: Colors.red)));
    }

    if (_stats == null) {
      return const Center(child: Text('No data available'));
    }

    final perf = _stats!['performance'] as Map<String, dynamic>? ?? {};
    final sust = _stats!['sustainability'] as Map<String, dynamic>? ?? {};
    final isEdge = _stats!['is_edge_mode_active'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isEdge),
          const SizedBox(height: 24),
          _buildMetricCard(
             title: 'Inference Latency',
             value: '${perf['latency_ms'] ?? '-'} ms',
             subtitle: isEdge ? '${perf['latency_improvement_percent']}% Faster' : 'Standard Response',
             icon: Icons.speed,
             color: isEdge ? Colors.green : Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildMetricCard(
             title: 'CO₂ per Scan',
             value: '${sust['co2_emitted_per_scan_grams'] ?? '-'} g',
             subtitle: isEdge ? 'Near Zero Emissions' : 'Cloud GPU Footprint',
             icon: Icons.co2,
             color: isEdge ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
           _buildMetricCard(
             title: 'Total CO₂ Saved',
             value: '${sust['total_co2_saved_grams'] ?? '-'} g',
             subtitle: 'By processing locally on ${ _stats!['hardware_profile'] }',
             icon: Icons.energy_savings_leaf,
             color: Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isEdge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEdge ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEdge ? Colors.green.withOpacity(0.5) : Colors.blue.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
             isEdge ? Icons.memory : Icons.cloud,
             size: 40,
             color: isEdge ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hardware Profile',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _stats!['hardware_profile'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isEdge ? Colors.green[800] : Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
