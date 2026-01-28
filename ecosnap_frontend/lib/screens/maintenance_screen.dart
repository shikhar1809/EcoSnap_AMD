import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart'; // Assuming fl_chart is added, if not I'll just use text/progress bars

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  _MaintenanceScreenState createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  // Mock list of appliances
  final List<Map<String, dynamic>> appliances = [
    {"type": "AC", "brand": "Voltas", "age": 4.0, "usage": 10.0, "last_service": 8},
    {"type": "Refrigerator", "brand": "Samsung", "age": 2.0, "usage": 24.0, "last_service": 14},
    {"type": "Washing Machine", "brand": "LG", "age": 6.0, "usage": 1.0, "last_service": 24},
  ];

  Map<String, dynamic>? currentAnalysis;
  bool isAnalyzing = false;

  Future<void> analyzeAppliance(Map<String, dynamic> appliance) async {
    setState(() {
      isAnalyzing = true;
      currentAnalysis = null;
    });

    final body = {
      "appliance_type": appliance['type'],
      "age_years": appliance['age'],
      "usage_hours_daily": appliance['usage'],
      "brand": appliance['brand'],
      "last_serviced_months_ago": appliance['last_service']
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/predictive/analyze'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentAnalysis = json.decode(response.body);
          isAnalyzing = false;
        });
      }
    } catch (e) {
      print("Error analyzing: $e");
      setState(() {
        isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Predictive Maintenance AI"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Your Appliances",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: appliances.length,
                itemBuilder: (ctx, index) {
                  final app = appliances[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.electrical_services),
                      title: Text("${app['brand']} ${app['type']}"),
                      subtitle: Text("Age: ${app['age']} yrs • Last Service: ${app['last_service']}m ago"),
                      trailing: ElevatedButton(
                        onPressed: () => analyzeAppliance(app),
                        child: const Text("Check Health"),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            if (isAnalyzing) const CircularProgressIndicator(),
            if (currentAnalysis != null) ...[
              const Text(
                "AI Diagnosis Result",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                color: currentAnalysis!['status'] == "Good" ? Colors.green.shade50 : (currentAnalysis!['status'] == "Warning" ? Colors.orange.shade50 : Colors.red.shade50),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Health Score: ${currentAnalysis!['health_score']}/100", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Chip(
                            label: Text(currentAnalysis!['status']),
                            backgroundColor: currentAnalysis!['status'] == "Good" ? Colors.green : (currentAnalysis!['status'] == "Warning" ? Colors.orange : Colors.red),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Failure Probability: ${(currentAnalysis!['failure_probability'] * 100).toStringAsFixed(1)}%"),
                      const SizedBox(height: 5),
                      Text("Predicted Failure: In ~${currentAnalysis!['predicted_failure_days']} days"),
                      const SizedBox(height: 10),
                      const Text("Recommendation:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(currentAnalysis!['recommendation']),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
