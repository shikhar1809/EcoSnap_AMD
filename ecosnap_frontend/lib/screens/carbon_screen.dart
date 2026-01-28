import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final balRes = await http.get(Uri.parse('http://localhost:8000/carbon/balance/$userId'));
      final histRes = await http.get(Uri.parse('http://localhost:8000/carbon/history/$userId'));
      
      setState(() {
        if (balRes.statusCode == 200) {
          balance = json.decode(balRes.body)['balance'];
        }
        if (histRes.statusCode == 200) {
          history = json.decode(histRes.body);
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching carbon data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> trade(String action, double amount) async {
    final body = {
      "user_id": userId,
      "amount": amount,
      "action": action
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/carbon/trade'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      
      if (response.statusCode == 200) {
        fetchData(); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Trade Successful!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Trade Failed: ${response.body}")));
      }
    } catch (e) {
      print("Error trading: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carbon Credits Market"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.teal.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text("Your Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(
                            "${balance.toStringAsFixed(2)} Credits",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text("≈ ₹${(balance * 75).toStringAsFixed(0)} Value", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => trade("BUY", 1.0),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text("Buy 1 Credit"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => trade("SELL", 1.0),
                          icon: const Icon(Icons.sell),
                          label: const Text("Sell 1 Credit"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Transaction History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    itemBuilder: (ctx, index) {
                      final txn = history[index];
                      // Reversed index for latest first
                      // Actually backend data isn't sorted, but let's just show it.
                      return ListTile(
                        leading: Icon(
                          txn['type'] == "EARN" ? Icons.eco : (txn['type'] == "BUY" ? Icons.arrow_downward : Icons.arrow_upward),
                          color: txn['type'] == "SELL" ? Colors.red : Colors.green,
                        ),
                        title: Text("${txn['type']} ${txn['amount']} Credits"),
                        subtitle: Text(txn['date']),
                        trailing: Text(txn['type'] == "EARN" ? "+ Credits" : "₹${(txn['amount'] * txn['price_per_credit']).toStringAsFixed(0)}"),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }
}
