import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubsidyScreen extends StatefulWidget {
  const SubsidyScreen({Key? key}) : super(key: key);

  @override
  _SubsidyScreenState createState() => _SubsidyScreenState();
}

class _SubsidyScreenState extends State<SubsidyScreen> {
  List<dynamic> schemes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSchemes();
  }

  Future<void> fetchSchemes() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:8000/subsidies/schemes'));
      if (response.statusCode == 200) {
        setState(() {
          schemes = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching schemes: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> applyForSubsidy(String schemeId, String schemeName) async {
    // Dummy apply logic
    final body = {
      "user_id": "test_user_id",
      "scheme_id": schemeId,
      "appliance_details": "New Appliance Request",
      "user_income_bracket": "Middle (5-10L)" 
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/subsidies/apply'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        _showStatusDialog(schemeName, result['status']);
      }
    } catch (e) {
      print("Error applying: $e");
    }
  }
  
  void _showStatusDialog(String schemeName, String status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Application Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == "Approved" ? Icons.check_circle : Icons.hourglass_top,
              color: status == "Approved" ? Colors.green : Colors.orange,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text("Applied for $schemeName"),
            const SizedBox(height: 10),
            Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Govt Subsidies"),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: schemes.length,
              itemBuilder: (ctx, index) {
                final scheme = schemes[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scheme['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(scheme['description']),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text("Max ₹${scheme['max_amount']}"),
                              backgroundColor: Colors.green.shade100,
                            ),
                            ElevatedButton(
                              onPressed: () => applyForSubsidy(scheme['id'], scheme['name']),
                              child: const Text("Apply Now"),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
