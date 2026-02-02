import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import 'dart:convert';

/// SIMPLE, WORKING ANALYSIS SCREEN
/// No complex flows, just: scan → analyze → show results
class SimpleAnalysisScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String imageName;
  
  const SimpleAnalysisScreen({
    super.key,
    required this.imageBytes,
    required this.imageName,
  });

  @override
  State<SimpleAnalysisScreen> createState() => _SimpleAnalysisScreenState();
}

class _SimpleAnalysisScreenState extends State<SimpleAnalysisScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      print('[SIMPLE ANALYSIS] Starting...');
      
      // Step 1: Get journey
      final context = await _api.getAnalysisQuestions(
        widget.imageBytes,
        widget.imageName,
        scanMode: 'quick',
      );
      
      print('[SIMPLE ANALYSIS] Context: ${context.keys}');
      
      final journey = context['journey_id'] ?? 'PRODUCT_SCAN';
      
      // Step 2: REAL ANALYSIS with Gemini + All APIs
      final result = await _api.uploadImage(
        widget.imageBytes,
        widget.imageName,
        {'journey_id': journey},
        demoMode: false, // REAL Gemini analysis with all 27 APIs
      );
      
      print('[SIMPLE ANALYSIS] Result: ${result.keys}');
      
      if (result.containsKey('error')) {
        setState(() {
          _error = result['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('[SIMPLE ANALYSIS] ERROR: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Analysis Results'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.greenAccent),
                  SizedBox(height: 20),
                  Text('Analyzing...', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 60),
                        const SizedBox(height: 20),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildResults(),
    );
  }

  Widget _buildResults() {
    if (_result == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(widget.imageBytes, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          
          // Journey Type
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Text(
                  _result!['journey'] ?? 'Analysis',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Product Name
          if (_result!.containsKey('product_name'))
            _buildInfoCard('Product', _result!['product_name'], Icons.shopping_bag),
          
          // Brand
          if (_result!.containsKey('brand'))
            _buildInfoCard('Brand', _result!['brand'], Icons.business),
          
          // Grade
          if (_result!.containsKey('sustainability_grade'))
            _buildInfoCard('Sustainability Grade', _result!['sustainability_grade'], Icons.grade),
          
          // Recommendation
          if (_result!.containsKey('recommendation'))
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.yellowAccent),
                      SizedBox(width: 10),
                      Text('Recommendation', style: TextStyle(color: Colors.yellowAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_result!['recommendation'], style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          
          // Confidence Score
          if (_result!.containsKey('confidence_score'))
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Confidence', style: TextStyle(color: Colors.white70)),
                  Text(
                    '${(_result!['confidence_score'] * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          
          // Data Sources
          if (_result!.containsKey('_data_sources'))
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Sources', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 5),
                  ...(_result!['_data_sources'] as List).map((source) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('• $source', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  )),
                ],
              ),
            ),
          
          const SizedBox(height: 30),
          
          // Debug: Show all keys
          ExpansionTile(
            title: const Text('Debug: All Data', style: TextStyle(color: Colors.white54, fontSize: 12)),
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(_result),
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
