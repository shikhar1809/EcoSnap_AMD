import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/advanced_feature_service.dart';

class AadhaarVerificationScreen extends StatefulWidget {
  const AadhaarVerificationScreen({super.key});

  @override
  State<AadhaarVerificationScreen> createState() => _AadhaarVerificationScreenState();
}

class _AadhaarVerificationScreenState extends State<AadhaarVerificationScreen> {
  final AdvancedFeatureService _featureService = AdvancedFeatureService();
  final TextEditingController _aadhaarController = TextEditingController();
  bool _isVerifying = false;
  Map<String, dynamic>? _result;

  void _verify() async {
    if (_aadhaarController.text.length < 4) return;
    setState(() => _isVerifying = true);
    final res = await _featureService.verifyAadhaar(_aadhaarController.text);
    if (mounted) {
      setState(() {
        _isVerifying = false;
        _result = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F2027),
      appBar: AppBar(
        title: Text("Subsidy Verification"), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.blueAccent),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (_result == null) ...[
              Icon(Icons.verified_user, size: 80, color: Colors.blueAccent),
              SizedBox(height: 24),
              Text("Link your Aadhaar for instant subsidy check", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text("We only store a secure hash, never your full number.", style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
              SizedBox(height: 40),
              TextField(
                controller: _aadhaarController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Last 4 digits of Aadhaar",
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  filled: true, fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verify,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: Size(double.infinity, 55)),
                child: _isVerifying ? CircularProgressIndicator(color: Colors.white) : Text("Consent & Verify", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Container(
                 padding: EdgeInsets.all(20),
                 decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.greenAccent)),
                 child: Row(
                   children: [
                     Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
                     SizedBox(width: 16),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Verification Successful", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                         Text("Aadhaar Linked: ${_result!['name']}", style: TextStyle(color: Colors.white70, fontSize: 12)),
                       ],
                     )
                   ],
                 ),
              ).animate().scale(),
              SizedBox(height: 40),
              Align(alignment: Alignment.centerLeft, child: Text("Eligible Subsidies Found:", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _result!['eligible_subsidies'].length,
                  itemBuilder: (context, index) {
                    final sub = _result!['eligible_subsidies'][index];
                    return Card(
                      color: Colors.white10,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(sub['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(sub['type'], style: TextStyle(color: Colors.white54)),
                        trailing: Text("₹${sub['amount']}", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
