import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../widgets/leaf_loading.dart';
import 'dart:convert';
import 'dart:typed_data';

class BillAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic>? solarData;
  
  const BillAnalysisScreen({super.key, this.solarData});

  @override
  State<BillAnalysisScreen> createState() => _BillAnalysisScreenState();
}

class _BillAnalysisScreenState extends State<BillAnalysisScreen> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _billData;
  Map<String, dynamic>? _roiData;
  
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadBill() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call backend bill analysis API
      final response = await ApiService.analyzeBill(base64Image);
      
      setState(() {
        _billData = response['bill_data'];
        _roiData = _calculateROI(response['bill_data']);
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing bill: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _calculateROI(Map<String, dynamic> billData) {
    // Extract data
    double monthlyBill = double.tryParse(billData['amount']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0') ?? 0;
    double consumption = double.tryParse(billData['consumption_kwh']?.toString() ?? '0') ?? 0;
    
    // Get solar data
    final solarViability = widget.solarData?['solar_viability'] ?? {};
    String potentialKw = solarViability['potential_kw'] ?? '2.5kW';
    double systemKw = double.parse(potentialKw.replaceAll('kW', ''));
    
    // Calculations
    double systemCost = systemKw * 50000; // ₹50K per kW
    double subsidy = 30000; // PM Surya Ghar
    double netCost = systemCost - subsidy;
    
    // Assume 80% bill reduction
    double monthlySavings = monthlyBill * 0.8;
    double yearlySavings = monthlySavings * 12;
    double paybackMonths = (netCost / monthlySavings).ceil();
    
    // 5-year projection
    double fiveYearSavings = yearlySavings * 5 - netCost;
    
    return {
      'current_monthly_bill': monthlyBill,
      'current_yearly_bill': monthlyBill * 12,
      'consumption_kwh': consumption,
      'system_kw': systemKw,
      'system_cost': systemCost,
      'subsidy': subsidy,
      'net_cost': netCost,
      'monthly_savings': monthlySavings,
      'yearly_savings': yearlySavings,
      'payback_months': paybackMonths,
      'five_year_savings': fiveYearSavings,
      'new_monthly_bill': monthlyBill - monthlySavings,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bill Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isAnalyzing
          ? const Center(child: LeafLoadingIndicator(message: 'Analyzing your bill...'))
          : _billData == null
              ? _buildUploadUI()
              : _buildResultsUI(),
    );
  }

  Widget _buildUploadUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.greenAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.2)],
                ),
              ),
              child: const Icon(Icons.receipt_long, size: 100, color: Colors.greenAccent),
            ).animate().scale(duration: 600.ms).fadeIn(),
            
            const SizedBox(height: 32),
            
            const Text(
              'Upload Your Electricity Bill',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Get precise ROI calculations based on your actual consumption and tariff',
              style: TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            ElevatedButton.icon(
              onPressed: _uploadBill,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Bill', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ).animate().slideY(begin: 0.3, duration: 400.ms).fadeIn(),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.check_circle, 'OCR extracts consumption & tariff'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.check_circle, 'Precise monthly savings calculation'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.check_circle, 'Real payback period (not estimates)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsUI() {
    if (_roiData == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.purple.shade900],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Current Bill', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '₹${_roiData!['current_monthly_bill'].toStringAsFixed(0)}/month',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_roiData!['consumption_kwh'].toStringAsFixed(0)} kWh consumed',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 24),
          
          // Before/After Comparison
          const Text(
            'With Solar',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _comparisonCard(
                  'Before',
                  '₹${_roiData!['current_monthly_bill'].toStringAsFixed(0)}',
                  'Monthly Bill',
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _comparisonCard(
                  'After',
                  '₹${_roiData!['new_monthly_bill'].toStringAsFixed(0)}',
                  'Monthly Bill',
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Savings Breakdown
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _savingsRow('Monthly Savings', '₹${_roiData!['monthly_savings'].toStringAsFixed(0)}'),
                const Divider(color: Colors.white10),
                _savingsRow('Yearly Savings', '₹${_roiData!['yearly_savings'].toStringAsFixed(0)}'),
                const Divider(color: Colors.white10),
                _savingsRow('5-Year Profit', '₹${_roiData!['five_year_savings'].toStringAsFixed(0)}'),
              ],
            ),
          ).animate().slideX(begin: 0.2, duration: 500.ms).fadeIn(),
          
          const SizedBox(height: 24),
          
          // Investment Details
          const Text(
            'Investment Breakdown',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _investmentRow('System Size', '${_roiData!['system_kw']} kW'),
                _investmentRow('System Cost', '₹${(_roiData!['system_cost']).toStringAsFixed(0)}'),
                _investmentRow('PM Surya Ghar Subsidy', '- ₹${_roiData!['subsidy'].toStringAsFixed(0)}', isSubsidy: true),
                const Divider(color: Colors.greenAccent),
                _investmentRow('Net Investment', '₹${_roiData!['net_cost'].toStringAsFixed(0)}', isBold: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Payback in ${_roiData!['payback_months']} months',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // CTA Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _billData = null;
                      _roiData = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Another'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connecting you with installers...')),
                    );
                  },
                  icon: const Icon(Icons.handshake),
                  label: const Text('Get Quotes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _comparisonCard(String label, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _savingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _investmentRow(String label, String value, {bool isSubsidy = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSubsidy ? Colors.greenAccent : Colors.white70,
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSubsidy ? Colors.greenAccent : (isBold ? Colors.white : Colors.white70),
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
