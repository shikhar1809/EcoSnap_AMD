import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CarbonScreen extends StatefulWidget {
  const CarbonScreen({Key? key}) : super(key: key);

  @override
  _CarbonScreenState createState() => _CarbonScreenState();
}

class _CarbonScreenState extends State<CarbonScreen> {
  double balance = 0.0;
  List<dynamic> history = [];
  bool isLoading = true;
  final String userId = "test_user_id";
  
  // No longer using Bill-Buster

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final balRes = await http.get(Uri.parse('http://localhost:8000/carbon/balance/$userId'));
      final histRes = await http.get(Uri.parse('http://localhost:8000/carbon/history/$userId'));
      
      if (mounted) {
        setState(() {
          if (balRes.statusCode == 200) {
            balance = json.decode(balRes.body)['balance'];
          }
          if (histRes.statusCode == 200) {
            history = json.decode(histRes.body);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching carbon data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }


  Future<void> trade(String action, double amount) async {
    final body = {"user_id": userId, "amount": amount, "action": action};
    try {
      final response = await http.post(Uri.parse('http://localhost:8000/carbon/trade'), 
          headers: {"Content-Type": "application/json"}, body: json.encode(body));
      if (response.statusCode == 200) {
        fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trade Successful!")));
      }
    } catch (e) {
      print("Error trading: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Carbon Credits 💸", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  const SizedBox(height: 30),
                  
                  // --- CARBON TRADING ---
                  Card(
                    color: Colors.teal.shade900.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text("Carbon Credits Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 10),
                          Text("${balance.toStringAsFixed(2)} Credits", style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                          Text("≈ ₹${(balance * 75).toStringAsFixed(0)} Value", style: const TextStyle(color: Colors.white38)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: ElevatedButton(onPressed: () => trade("BUY", 1.0), child: const Text("Buy"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green))),
                              const SizedBox(width: 10),
                              Expanded(child: ElevatedButton(onPressed: () => trade("SELL", 1.0), child: const Text("Sell"), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent))),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
