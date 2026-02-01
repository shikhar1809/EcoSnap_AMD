import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/leaf_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert'; // For Base64 decoding
import 'dart:typed_data';
import '../widgets/scanner_v2.dart'; // V2 Redesign import
import 'chat_screen.dart';
import 'office_snap_screen.dart';
import 'leaderboard_screen.dart';
import 'community_screen.dart';
import 'subsidy_screen.dart';
import 'maintenance_screen.dart';
import 'marketplace_screen.dart';
import 'carbon_screen.dart';
import '../widgets/questionnaire_dialog.dart';
import 'top_picks_screen.dart';
import '../widgets/voice_agent_widget.dart';
import '../widgets/infinite_marquee.dart';
import '../widgets/verification_dialog.dart';
import 'furniture_ar_screen.dart';
import 'solar_ar_screen.dart';
import 'aadhaar_verification_screen.dart';
import 'eco_farm_screen.dart';
import '../widgets/scan_button.dart';
import '../widgets/scan_mode_toggle.dart';
import 'room_helpers.dart';
// Hackathon winning widgets
import '../widgets/live_impact_counter.dart';
import '../widgets/sdg_badges.dart';
import '../widgets/impact_passport.dart';
import '../widgets/voice_agent.dart';
import '../widgets/green_ai_metrics.dart';
import 'impact_passport_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService();
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStage = "Starting...";
  String _scanMode = "quick"; // Toggle State
  Uint8List? _currentImageBytes;
  Map<String, dynamic> _lastAnalysisData = {};
  
  // 🔥 Gamification - Streak tracking
  int _currentStreak = 3; // Demo: 3-day streak
  bool _hasScannedToday = false;
  
  // 💡 Rotating daily tips
  final List<Map<String, String>> _dailyTips = [
    {"tip": "Switching to LED bulbs can save ₹2,000/year", "icon": "💡"},
    {"tip": "A 5-minute shower uses 40L less water than a bath", "icon": "🚿"},
    {"tip": "Unplugging chargers saves 10% on electricity", "icon": "🔌"},
    {"tip": "One mature tree absorbs 22kg CO₂ per year", "icon": "🌳"},
    {"tip": "Solar panels pay back in 4-5 years in India", "icon": "☀️"},
    {"tip": "Electric vehicles save ₹50,000/year on fuel", "icon": "🚗"},
    {"tip": "Composting reduces household waste by 30%", "icon": "🌱"},
  ];
  int _tipIndex = 0;
  
  // Detected product for scanner overlay
  String? _detectedProduct;
  
  // Order of dashboard cards
  List<String> _cardOrder = ['did_you_know', 'challenge', 'maintenance', 'top_picks'];

  // Calculate payback progress (shorter = better = higher progress)
  double _calculatePaybackProgress(dynamic months) {
    int paybackMonths = months is int ? months : (int.tryParse(months?.toString() ?? '60') ?? 60);
    // Inverse relationship: 12 months = 100%, 60 months = 20%
    return (1.0 - (paybackMonths.clamp(0, 60) / 60)).clamp(0.2, 1.0);
  }

  Widget _unlockStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }

  Widget _wasteLine(String period, String amount, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(period, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))),
        ],
      ),
    );
  }


  Future<void> _uploadVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing Video Audit...")));
        setState(() {
          _isAnalyzing = true;
          _analysisStage = "Preparing video for deep audit...";
          _analysisProgress = 0.2;
        });
      }
      
      // Mocking video analysis by reusing a sample image for the results UI
      final bytes = await (await _picker.pickImage(source: ImageSource.gallery, imageQuality: 10))?.readAsBytes();
      if (bytes != null) {
         try {
           final result = await apiService.uploadImage(bytes, "video_frame.jpg", {"type": "video_audit"});
           if (mounted) {
             setState(() {
               _isAnalyzing = false;
               _lastAnalysisData = result;
             });
             _showResults(result, bytes, "Advanced Video Audit");
           }
         } catch (e) {
           if (mounted) setState(() => _isAnalyzing = false);
         }
      } else {
        if (mounted) setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      String? userNote;
      if (mounted && _scanMode != 'quick') {
        userNote = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: const Text("Any context?", style: TextStyle(color: Colors.white)),
            content: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "E.g. 'Old radio', 'Plastic bottle'", hintStyle: TextStyle(color: Colors.white38)),
              onSubmitted: (val) => Navigator.pop(ctx, val),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Skip")),
              TextButton(onPressed: () => Navigator.pop(ctx, "confirmed"), child: const Text("Next")),
            ],
          )
        );
      }
      
      // Inject Scan Mode
      userNote = "${userNote ?? ''} [MODE: $_scanMode]";

      if (mounted) {
         setState(() {
           _isAnalyzing = true; 
           _currentImageBytes = bytes;
         });
         
         // Safety timeout to prevent stuck UI
         Future.delayed(const Duration(seconds: 30), () {
            if (mounted && _isAnalyzing) {
              setState(() {
                _isAnalyzing = false;
                _analysisStage = ""; 
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analysis taking too long. Resetting scanner.")));
            }
         });
      }

      try {
        setState(() {
          _isAnalyzing = true;
          _analysisProgress = 0.3;
          _analysisStage = "Smart Triage analyzing...";
        });
        
        // Pass scan mode to backend
        final contextResult = await apiService.getAnalysisQuestions(
          bytes, 
          image.name, 
          userNote: userNote,
          scanMode: _scanMode,  // NEW: Pass quick/deep mode
        );
        
        setState(() {
          _analysisProgress = 0.6;
          _analysisStage = "Classifying journey...";
        });

        if (mounted) {
           // Clear the overlay
           // Keep overlay text updating but DO NOT dismiss
           setState(() {
             _analysisStage = "Analyzing context...";
           });
           
           await Future.delayed(const Duration(milliseconds: 1500));

           if (!mounted) return;

           final verification = Map<String, dynamic>.from(contextResult['verification'] ?? {});
           final questions = contextResult['questions'] as List? ?? [];
           final detectedJourney = contextResult['journey_id'] ?? 'SPECIAL';
           final confidence = (contextResult['confidence'] ?? 0.5).toDouble();
           final autoProc = contextResult['auto_proceed'] ?? false;
           
           // NEW LOGIC: Smart Triage for BOTH modes
           // Quick mode: Auto-proceed if high confidence, else show triage
           // Deep mode: Always show triage
           
           if (_scanMode == 'quick' && autoProc && confidence > 0.85) {
               // High confidence quick scan - proceed directly
               if (mounted) setState(() => _isAnalyzing = true);
               try {
                   final answers = {
                       'journey_id': detectedJourney,
                       'auto_detected': true,
                       'confidence': confidence,
                   };
                   final result = await apiService.uploadImage(bytes, image.name, answers);
                   if (mounted) {
                       setState(() {
                         _isAnalyzing = false;
                         _lastAnalysisData = result;
                       });
                       _showJourneyResults(result, bytes);
                   }
               } catch (e) {
                   if (mounted) setState(() => _isAnalyzing = false);
               }
               return; 
           }
           
           // Show Smart Triage Dialog (both modes come here if not auto-proceeded)
           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => VerificationDialog(
               verificationData: verification,
               detectedJourneyId: detectedJourney,
               confidence: confidence,
               autoProceeed: autoProc,
               onResult: (isConfirmed, correctedCategory, finalJourneyId) async {
                  Navigator.pop(ctx); 
                  
                  // Quick mode: Skip questionnaire
                  if (_scanMode == 'quick') {
                    if (mounted) setState(() => _isAnalyzing = true);
                    try {
                      final answers = {
                        'journey_id': finalJourneyId,
                        'user_correction': correctedCategory,
                      };
                      final result = await apiService.uploadImage(bytes, image.name, answers);
                      if (mounted) {
                        setState(() {
                          _isAnalyzing = false;
                          _lastAnalysisData = result;
                        });
                        _showJourneyResults(result, bytes);
                      }
                    } catch (e) {
                      if (mounted) setState(() => _isAnalyzing = false);
                    }
                    return;
                  }
                  // Deep mode: Show questionnaire
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (qCtx) => QuestionnaireDialog(
                      questions: questions,
                      onSubmit: (answers) async {
                         if (mounted) setState(() => _isAnalyzing = true);
                         try {
                           if (correctedCategory != null) {
                             answers['user_correction'] = correctedCategory;
                           }
                           answers['journey_id'] = finalJourneyId;
                           
                           final result = await apiService.uploadImage(bytes, image.name, answers);
                           if (mounted) {
                              setState(() {
                                _isAnalyzing = false;
                                _lastAnalysisData = result;
                              });
                              _showJourneyResults(result, bytes);
                           }
                         } catch (e) {
                           if (mounted) setState(() => _isAnalyzing = false);
                         }
                      },
                    ),
                  );
               }
             )
           );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildProcessingOverlay() {
    return ScannerV2Widget(
      imageBytes: _currentImageBytes,
      detectedProduct: _detectedProduct, // Pass detected product if available
      onComplete: () {
        // Optional: Auto-dismiss if needed, but the logic is handled in _uploadImage
      },
    );
  }

  Future<String?> _showBudgetDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimpleDialog(
        title: const Text('Set Your Budget'),
        backgroundColor: Colors.grey.shade900,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        children: [
          _budgetOption("Low (< ₹2,000)", "Low"),
          _budgetOption("Medium (₹2k - ₹10k)", "Medium"),
          _budgetOption("High (> ₹10,000)", "High"),
          _budgetOption("No Limit", "Unlimited"),
        ],
      ),
    );
  }

  Widget _budgetOption(String label, String value) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Icon(Icons.arrow_forward_ios, color: Colors.greenAccent, size: 16)
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonAuditView(Map<String, dynamic> data) {
    // Get actual product carbon data from API response
    final carbonData = Map<String, dynamic>.from(data['carbon_footprint'] ?? {});
    final productName = data['product_name'] ?? data['identified_object'] ?? 'Scanned Item';
    final annualCo2 = carbonData['annual_co2_kg'] ?? carbonData['total_kg'] ?? 2.5;
    final perUnit = carbonData['per_unit_kg'] ?? 0.25;
    
    // Generate contextual carbon breakdown for this product
    final breakdown = _getProductCarbonBreakdown(productName, annualCo2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CARBON FOOTPRINT ANALYSIS", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          
          // Product Carbon Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.withOpacity(0.2), Colors.orange.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Carbon Impact: HIGH", style: TextStyle(color: Colors.redAccent.shade100, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${annualCo2.toStringAsFixed(1)} kg", style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text("CO₂/year", style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (annualCo2 as num) / 10.0 > 1 ? 1 : (annualCo2 as num) / 10.0,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(annualCo2 > 5 ? Colors.redAccent : Colors.orangeAccent),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Text("CARBON BREAKDOWN", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          
          ...breakdown.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      Text(item['desc'] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                ),
                Text(item['value'] as String, style: TextStyle(color: item['color'] as Color, fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 16),
          
          // Comparison
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Switch to eco alternative?", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Text("Save up to ${(annualCo2 * 0.8).toStringAsFixed(1)} kg CO₂/year", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.greenAccent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _getProductCarbonBreakdown(String productName, dynamic totalCo2) {
    // Generate appropriate breakdown based on product
    final total = (totalCo2 as num).toDouble();
    return [
      {"name": "Manufacturing", "desc": "Production & packaging", "value": "${(total * 0.4).toStringAsFixed(2)} kg", "icon": Icons.factory, "color": Colors.orangeAccent},
      {"name": "Transportation", "desc": "Shipping & distribution", "value": "${(total * 0.35).toStringAsFixed(2)} kg", "icon": Icons.local_shipping, "color": Colors.redAccent},
      {"name": "Disposal", "desc": "End of life impact", "value": "${(total * 0.25).toStringAsFixed(2)} kg", "icon": Icons.delete_outline, "color": Colors.amber},
    ];
  }

  void _showCarbonAudit(Map<String, dynamic> data, Uint8List imageBytes) {
     _showResults(data, imageBytes, "Implicit");
  }

  /// Routes to the appropriate result UI based on journey type
  void _showJourneyResults(Map<String, dynamic> data, Uint8List imageBytes) {
    final journey = data['journey'] ?? data['journey_type'] ?? 'SPECIAL';
    
    switch (journey) {
      case 'SOLAR_AUDIT':
        // Solar audit gets special AR-enabled view
        _showSolarAuditResults(data, imageBytes);
        break;
      case 'ROOM_ENERGY':
        // Room audit shows appliance efficiency focus
        _showRoomEnergyResults(data, imageBytes);
        break;
      case 'BILL_OCR':
        // Bill analysis shows tariff breakdown
        _showBillAnalysisResults(data, imageBytes);
        break;
      case 'FOOD_AUDIT':
        // Food audit shows carbon per ingredient
        _showFoodAuditResults(data, imageBytes);
        break;
      case 'VEHICLE_CHECK':
        // Vehicle check shows EV comparison
        _showVehicleCheckResults(data, imageBytes);
        break;
      case 'PRODUCT_SCAN':
      default:
        // Product scan and default use the standard results view
        _showResults(data, imageBytes, "Analysis");
    }
  }

  void _showSolarAuditResults(Map<String, dynamic> data, Uint8List imageBytes) {
    final solar = Map<String, dynamic>.from(data['solar_analysis'] ?? {});
    final financials = Map<String, dynamic>.from(data['financials'] ?? {});
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text("☀️", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Expanded(child: Text("Solar Potential", style: TextStyle(color: Colors.white))),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Viability Score
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.3), Colors.transparent]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Solar Viability Score", style: TextStyle(color: Colors.white70)),
                      Text("${solar['viability_score'] ?? 85}/100", 
                        style: const TextStyle(color: Colors.orange, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Roof Analysis
                _buildInfoTile("🏠 Roof Area", "${solar['roof_area_sqm'] ?? 40} sq.m usable"),
                _buildInfoTile("☀️ Sunlight", "${solar['sunlight_quality'] ?? 'Good'} (${solar['sunlight_hours'] ?? 5} hrs/day)"),
                _buildInfoTile("⚡ Recommended", "${solar['recommended_capacity_kw'] ?? 3} kW system"),
                
                const Divider(color: Colors.white24, height: 32),
                
                // Financial Projection
                const Text("💰 FINANCIAL PROJECTION", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFinancialRow("System Cost", "₹${financials['system_cost'] ?? 180000}"),
                _buildFinancialRow("PM Surya Ghar Subsidy", "-₹${financials['pm_surya_ghar_subsidy'] ?? 78000}", isGreen: true),
                _buildFinancialRow("State Subsidy", "-₹${financials['state_subsidy'] ?? 15000}", isGreen: true),
                const Divider(color: Colors.white24),
                _buildFinancialRow("Your Cost", "₹${financials['net_cost'] ?? 87000}", isBold: true),
                _buildFinancialRow("Monthly Savings", "₹${financials['monthly_savings'] ?? 2800}/month", isGreen: true),
                _buildFinancialRow("Payback", "${financials['payback_months'] ?? 31} months"),
                
                const Divider(color: Colors.white24, height: 32),
                
                // SDG Impact (Hackathon Feature)
                const SdgBadges(sdgNumbers: [7, 11, 13]),
                
                const SizedBox(height: 16),
                
                // Green AI metrics
                const GreenAiReport(journeyType: 'SOLAR_AUDIT'),
                
                const SizedBox(height: 20),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SolarARScreen()));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        icon: const Icon(Icons.view_in_ar, color: Colors.white),
                        label: const Text("AR Preview", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubsidyScreen()));
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                        icon: const Icon(Icons.money, color: Colors.greenAccent),
                        label: const Text("Subsidies", style: TextStyle(color: Colors.greenAccent)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoomEnergyResults(Map<String, dynamic> data, Uint8List imageBytes) {
    final appliances = (data['detected_appliances'] as List?) ?? [];
    final vampirePower = Map<String, dynamic>.from(data['vampire_power'] ?? {});
    final quickWins = (data['quick_wins'] as List?) ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text("🛋️", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text("Room Energy: ${data['efficiency_score'] ?? 65}/100", style: const TextStyle(color: Colors.white))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appliances
                const Text("🔌 DETECTED APPLIANCES", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...appliances.map((a) => _buildApplianceTile(Map<String, dynamic>.from(a))),
                
                if (vampirePower['detected'] == true) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Text("👻", style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text("Vampire Power: ${vampirePower['sources']?.join(', ') ?? 'Standby devices'} wasting ₹${vampirePower['annual_cost_inr'] ?? 400}/year",
                            style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (quickWins.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text("💡 QUICK WINS", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ...quickWins.map((q) {
                    final qw = Map<String, dynamic>.from(q);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.bolt, color: Colors.yellow),
                      title: Text(qw['item'] ?? 'Item', style: const TextStyle(color: Colors.white)),
                      subtitle: Text("₹${qw['cost']} → Save ₹${qw['annual_savings']}/yr", style: const TextStyle(color: Colors.white54)),
                    );
                  }),
                ],
                
                const SizedBox(height: 16),
                Text("📊 Total Potential Savings: ₹${data['total_potential_savings_year'] ?? 5000}/year",
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplianceTile(Map<String, dynamic> appliance) {
    final status = appliance['status'] ?? 'average';
    final color = status == 'efficient' ? Colors.green : (status == 'inefficient' ? Colors.red : Colors.orange);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(status == 'efficient' ? Icons.check_circle : Icons.warning, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appliance['name'] ?? 'Appliance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (appliance['upgrade_suggestion'] != null)
                  Text("Upgrade: ${appliance['upgrade_suggestion']} → Save ₹${appliance['annual_savings_inr']}/yr",
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBillAnalysisResults(Map<String, dynamic> data, Uint8List imageBytes) {
    final extracted = Map<String, dynamic>.from(data['extracted_data'] ?? {});
    final strategies = (data['reduction_strategies'] as List?) ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text("📄", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Expanded(child: Text("Bill Analysis", style: TextStyle(color: Colors.white))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Units Consumed", style: TextStyle(color: Colors.white70)),
                        Text("${extracted['units_consumed'] ?? 342} kWh", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Total Amount", style: TextStyle(color: Colors.white70)),
                        Text("₹${extracted['total_amount_inr'] ?? 2847}", style: const TextStyle(color: Colors.purpleAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text("💡 REDUCTION STRATEGIES", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...strategies.map((s) {
                  final strat = Map<String, dynamic>.from(s);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.trending_down, color: Colors.green),
                    title: Text(strat['strategy'] ?? 'Strategy', style: const TextStyle(color: Colors.white)),
                    subtitle: Text("Save ₹${strat['monthly_savings_inr'] ?? 0}/month", style: const TextStyle(color: Colors.greenAccent)),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFoodAuditResults(Map<String, dynamic> data, Uint8List imageBytes) {
    final carbon = Map<String, dynamic>.from(data['carbon_footprint'] ?? {});
    final swaps = (data['greener_swaps'] as List?) ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text("🍎", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(data['product_name'] ?? 'Food Audit', style: const TextStyle(color: Colors.white))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Carbon Footprint", style: TextStyle(color: Colors.white70)),
                      Text("${carbon['total_kg_co2'] ?? 3.2} kg CO₂", style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text("🥗 GREENER SWAPS", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ...swaps.map((s) {
                  final swap = Map<String, dynamic>.from(s);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.swap_horiz, color: Colors.green),
                    title: Text("${swap['swap_from']} → ${swap['swap_to']}", style: const TextStyle(color: Colors.white)),
                    subtitle: Text("-${swap['carbon_reduction_percent']}% carbon", style: const TextStyle(color: Colors.greenAccent)),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVehicleCheckResults(Map<String, dynamic> data, Uint8List imageBytes) {
    final evComp = Map<String, dynamic>.from(data['ev_comparison'] ?? {});
    final emissions = Map<String, dynamic>.from(data['emissions'] ?? {});
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Text("🚗", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(data['product_name'] ?? 'Vehicle Check', style: const TextStyle(color: Colors.white))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.teal.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text("Annual Emissions", style: TextStyle(color: Colors.white70)),
                        Text("${emissions['annual_kg_co2'] ?? 2400} kg", style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text("🔋 EV SWITCH SAVINGS", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoTile("Recommended EV", evComp['recommended_ev'] ?? 'Tata Nexon EV'),
                _buildInfoTile("Annual Fuel Savings", "₹${evComp['annual_fuel_savings'] ?? 102000}"),
                _buildInfoTile("FAME-II Subsidy", "₹${evComp['fame_subsidy'] ?? 150000}"),
                _buildInfoTile("Breakeven", "${evComp['breakeven_years'] ?? 4.2} years"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(
            color: isGreen ? Colors.greenAccent : Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          )),
        ],
      ),
    );
  }

  void _showResults(Map<String, dynamic> data, Uint8List imageBytes, String budget) {
    // SMART CONTEXTUAL TABS - Show only relevant tabs based on what was scanned
    final journey = data['journey'] ?? data['journey_type'] ?? 'PRODUCT_SCAN';
    final type = data['type'] ?? '';
    
    // Get smart tabs and views based on context
    final smartTabs = _getSmartTabs(journey, type, data);
    final smartViews = _getSmartViews(journey, type, data);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          height: 650, 
          child: Stack(
            children: [
              Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.memory(imageBytes, fit: BoxFit.cover),
                    ),
                  ),
                  
                  Expanded(
                    child: DefaultTabController(
                      length: smartTabs.length,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            labelColor: Colors.greenAccent,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.greenAccent,
                            tabs: smartTabs,
                          ),
                          Expanded(
                            child: TabBarView(
                              children: smartViews,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (type == 'property_exterior' || journey == 'SOLAR_AUDIT')
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (kIsWeb) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AR Preview is only available on mobile devices.'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SolarARScreen(solarData: data)));
                      }
                    },
                    label: const Text("AR PREVIEW", style: TextStyle(fontWeight: FontWeight.bold)),
                    icon: const Icon(Icons.view_in_ar),
                    backgroundColor: Colors.orangeAccent,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
    );
    _checkAndShowUnlock();
  }
  
  /// Returns SMART contextual tabs based on what was scanned
  List<Tab> _getSmartTabs(String journey, String type, Map<String, dynamic> data) {
    if (type == 'room' || type == 'room_interior') {
      return const [Tab(text: "Overview"), Tab(text: "Appliances"), Tab(text: "Architecture"), Tab(text: "Maintenance")];
    }
    
    switch (journey) {
      case 'PRODUCT_SCAN':
        // Products: Show alternatives, carbon, eco-score
        return const [Tab(text: "🌱 Green Swaps"), Tab(text: "Carbon Footprint"), Tab(text: "Eco Score"), Tab(text: "Community")];
      case 'BILL_OCR':
        // Bills: Show savings, subsidies, economics
        return const [Tab(text: "💰 Savings"), Tab(text: "Subsidies"), Tab(text: "Economics"), Tab(text: "Usage Tips")];
      case 'SOLAR_AUDIT':
        // Solar: Show financials, subsidies, installation
        return const [Tab(text: "☀️ Solar Potential"), Tab(text: "Subsidies"), Tab(text: "Economics"), Tab(text: "Top Picks")];
      case 'FOOD_AUDIT':
        // Food: Show carbon, alternatives, nutrition
        return const [Tab(text: "🍃 Food Impact"), Tab(text: "Green Swaps"), Tab(text: "Carbon Footprint"), Tab(text: "Community")];
      case 'VEHICLE_CHECK':
        // Vehicle: Show EV comparison, maintenance, economics
        return const [Tab(text: "🚗 EV Comparison"), Tab(text: "Maintenance"), Tab(text: "Economics"), Tab(text: "Carbon Footprint")];
      default:
        return const [Tab(text: "Impact"), Tab(text: "Green Swaps"), Tab(text: "Carbon Footprint"), Tab(text: "Community")];
    }
  }
  
  /// Returns SMART contextual views based on what was scanned
  List<Widget> _getSmartViews(String journey, String type, Map<String, dynamic> data) {
    if (type == 'room' || type == 'room_interior') {
      return [buildRoomOverviewTab(data), buildRoomAppliancesTab(data), buildGreenArchitectureTab(data), const MaintenanceScreen()];
    }
    
    switch (journey) {
      case 'PRODUCT_SCAN':
        return [_buildGreenAlternativesTab(data), _buildCarbonAuditView(data), _buildImpactTab(data), _buildCommunityTab(data)];
      case 'BILL_OCR':
        return [_buildImpactTab(data), const SubsidyScreen(), _buildEconomicsTab(data), _buildCommunityTab(data)];
      case 'SOLAR_AUDIT':
        return [_buildImpactTab(data), const SubsidyScreen(), _buildEconomicsTab(data), const TopPicksScreen()];
      case 'FOOD_AUDIT':
        return [_buildImpactTab(data), _buildGreenAlternativesTab(data), _buildCarbonAuditView(data), _buildCommunityTab(data)];
      case 'VEHICLE_CHECK':
        return [_buildImpactTab(data), const MaintenanceScreen(), _buildEconomicsTab(data), _buildCarbonAuditView(data)];
      default:
        return [_buildImpactTab(data), _buildGreenAlternativesTab(data), _buildCarbonAuditView(data), _buildCommunityTab(data)];
    }
  }
  
  /// 🌱 GREEN ALTERNATIVES TAB - The key feature for product scans!
  Widget _buildGreenAlternativesTab(Map<String, dynamic> data) {
    final alts = data['alternatives'] as List? ?? [];
    final productName = data['product_name'] ?? data['identified_object'] ?? 'This Product';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.3), Colors.teal.withOpacity(0.2)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco, color: Colors.greenAccent, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🌱 GREENER ALTERNATIVES", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("Eco-friendly swaps for $productName", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (alts.isEmpty)
            _buildDemoAlternatives(productName)
          else
            ...alts.map((alt) => _buildAlternativeCard(alt)).toList(),
          
          const SizedBox(height: 16),
          
          // SDG Badge
          const SdgBadges(sdgNumbers: [12, 13]),
        ],
      ),
    );
  }
  
  Widget _buildDemoAlternatives(String productName) {
    // SMART product-specific alternatives based on detected product
    final lowerName = productName.toLowerCase();
    List<Map<String, String>> demoAlts;
    
    if (lowerName.contains('coca') || lowerName.contains('cola') || lowerName.contains('pepsi') || lowerName.contains('soda') || lowerName.contains('soft drink')) {
      demoAlts = [
        {"name": "Coconut Water", "brand": "Paper Boat", "savings": "1.8 kg CO₂/unit", "impact": "Low", "reason": "Natural, biodegradable packaging"},
        {"name": "Homemade Lemonade", "brand": "DIY", "savings": "2.4 kg CO₂/unit", "impact": "Zero", "reason": "No packaging, no transport"},
        {"name": "Sparkling Water", "brand": "Glass Bottle", "savings": "1.2 kg CO₂/unit", "impact": "Low", "reason": "Reusable glass container"},
      ];
    } else if (lowerName.contains('bottle') || lowerName.contains('water') || lowerName.contains('aqua')) {
      demoAlts = [
        {"name": "Glass Water Bottle", "brand": "Local Springs", "savings": "2.1 kg CO₂/month", "impact": "Very Low", "reason": "Reusable, no plastic waste"},
        {"name": "Copper Bottle", "brand": "Ayurveda Pure", "savings": "3.5 kg CO₂/month", "impact": "Zero", "reason": "Traditional, anti-bacterial, lifetime use"},
        {"name": "Filtered Tap Water", "brand": "RO System", "savings": "4.2 kg CO₂/month", "impact": "Minimal", "reason": "No transport emissions, no plastic"},
      ];
    } else if (lowerName.contains('phone') || lowerName.contains('mobile') || lowerName.contains('iphone') || lowerName.contains('samsung')) {
      demoAlts = [
        {"name": "Refurbished Phone", "brand": "Certified Pre-owned", "savings": "45 kg CO₂/device", "impact": "Low", "reason": "70% less manufacturing emissions"},
        {"name": "Fairphone", "brand": "Fairphone", "savings": "35 kg CO₂/device", "impact": "Medium", "reason": "Modular, repairable, ethical sourcing"},
        {"name": "Keep Current Phone", "brand": "Extend Life", "savings": "70 kg CO₂/year", "impact": "Zero", "reason": "Best eco choice is not buying new"},
      ];
    } else if (lowerName.contains('bag') || lowerName.contains('plastic')) {
      demoAlts = [
        {"name": "Cloth Tote Bag", "brand": "Local Artisan", "savings": "0.5 kg CO₂/use", "impact": "Very Low", "reason": "Reusable 500+ times"},
        {"name": "Jute Bag", "brand": "EcoJute", "savings": "0.4 kg CO₂/use", "impact": "Zero", "reason": "100% biodegradable natural fiber"},
        {"name": "Paper Bag", "brand": "Recycled", "savings": "0.2 kg CO₂/use", "impact": "Low", "reason": "Recyclable, compostable"},
      ];
    } else if (lowerName.contains('cloth') || lowerName.contains('shirt') || lowerName.contains('dress') || lowerName.contains('fashion')) {
      demoAlts = [
        {"name": "Organic Cotton", "brand": "Sustainable Brands", "savings": "3.2 kg CO₂/item", "impact": "Low", "reason": "No pesticides, less water"},
        {"name": "Second-hand Thrift", "brand": "Local Thrift Store", "savings": "8 kg CO₂/item", "impact": "Zero", "reason": "No new manufacturing"},
        {"name": "Hemp Fabric", "brand": "EcoWear", "savings": "2.8 kg CO₂/item", "impact": "Very Low", "reason": "Grows without pesticides"},
      ];
    } else {
      // Generic eco alternatives
      demoAlts = [
        {"name": "Eco-Certified Alternative", "brand": "Green Choice", "savings": "1.5 kg CO₂/unit", "impact": "Low", "reason": "Certified sustainable sourcing"},
        {"name": "Second-hand Option", "brand": "Preloved", "savings": "3.0 kg CO₂/unit", "impact": "Very Low", "reason": "No new manufacturing needed"},
        {"name": "Local Made", "brand": "Made in India", "savings": "1.2 kg CO₂/unit", "impact": "Low", "reason": "Reduced transport emissions"},
      ];
    }
    
    return Column(
      children: demoAlts.map((alt) => _buildAlternativeCard(alt)).toList(),
    );
  }
  
  Widget _buildAlternativeCard(dynamic alt) {
    final name = alt['name'] ?? 'Eco Alternative';
    final brand = alt['brand'] ?? '';
    final savings = alt['savings'] ?? alt['co2_savings'] ?? '1.5 kg CO₂/month';
    final impact = alt['impact'] ?? 'Low';
    final reason = alt['reason'] ?? alt['why_better'] ?? 'More sustainable choice';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz, color: Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                if (brand.isNotEmpty) Text(brand, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                const SizedBox(height: 4),
                Text(reason, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: impact == 'Zero' ? Colors.green : impact == 'Very Low' ? Colors.teal : Colors.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(impact, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(savings, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactTab(Map<String, dynamic> data) {
    final carbon = Map<String, dynamic>.from(data['carbon_footprint'] ?? {});
    final score = Map<String, dynamic>.from(data['sustainability_score'] ?? {});
    final alts = data['alternatives'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.2), Colors.purpleAccent.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['product_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(data['condition_assessment'] ?? 'Analysis Complete', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 12),
                      const SizedBox(width: 4),
                      Text("AI Estimate • ${((data['confidence_score'] ?? 0.85) * 100).toInt()}% Confidence", 
                           style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ]),
                  ]),
                ),
                Container(
                  width: 50, height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _getScoreColor(score['grade']), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _getScoreColor(score['grade']).withOpacity(0.4), blurRadius: 10)]),
                  child: Text(score['grade'] ?? '?', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          _infoCard(Icons.warning_amber, "Cost Inefficiency", data['economics']?['monthly_savings'] ?? "₹500", "Wasted per month if not upgraded"),
          
          const SizedBox(height: 24),
          _buildDynamicImpactCard(carbon),
          
          // Cost of Inaction Warning
          const SizedBox(height: 24),
          _buildCostOfInactionCard(data),
          
          if (alts.isNotEmpty) ...[
             const SizedBox(height: 24),
             const Text("Better Alternatives Found!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 12),
             ...alts.asMap().entries.map((entry) {
               int idx = entry.key;
               var alt = entry.value;
               bool isMostPopular = idx == 0; // First alternative is most popular
               
               return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TopPicksScreen()));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isMostPopular 
                      ? LinearGradient(colors: [Colors.green.withOpacity(0.2), Colors.teal.withOpacity(0.1)])
                      : null,
                    color: isMostPopular ? null : Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMostPopular ? Colors.greenAccent : Colors.greenAccent.withOpacity(0.3),
                      width: isMostPopular ? 2 : 1,
                    )
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMostPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.trending_up, size: 12, color: Colors.black),
                              SizedBox(width: 4),
                              Text("MOST POPULAR", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.eco, color: Colors.greenAccent, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alt['name'] ?? 'Eco Alternative', 
                                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.savings, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text("${alt['carbon_savings']}", 
                                         style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ]
                            )
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(alt['price_estimate'] ?? '—', 
                                   style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 2),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
             }),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _commitToAction(context),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text("I'll Do This!", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEcoStoryDialog(context, data),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text("Share Story"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _commitToAction(BuildContext context) {
    showDialog(
       context: context,
       builder: (ctx) => Dialog(
         backgroundColor: Colors.transparent,
         child: Container(
           padding: const EdgeInsets.all(20),
           decoration: BoxDecoration(
             color: Colors.black.withOpacity(0.9),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.greenAccent)
           ),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.stars, color: Colors.amber, size: 60).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
               const SizedBox(height: 20),
               const Text("Points Added!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
               const SizedBox(height: 10),
               const Text("+50 XP", style: TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               const Text("You are now a 'Green Rookie'!", style: TextStyle(color: Colors.white70)),
               const SizedBox(height: 20),
               ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text("Awesome!"))
             ],
           ),
         ),
       )
    );
  }

  Widget _buildEconomicsTab(Map<String, dynamic> data) {
    final eco = Map<String, dynamic>.from(data['economics'] ?? {});
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: Colors.black26, 
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.amber.withOpacity(0.5))
             ),
             child: Column(
               children: [
                 const Text("PAYBACK TIMER", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                 const SizedBox(height: 20),
                 Stack(
                   alignment: Alignment.center,
                   children: [
                     SizedBox(
                       width: 120, height: 120,
                       child: CircularProgressIndicator(
                         value: _calculatePaybackProgress(eco['payback_period_months']), 
                         strokeWidth: 10, 
                         backgroundColor: Colors.white10, 
                         valueColor: const AlwaysStoppedAnimation(Colors.amber)
                       ),
                     ),
                     Column(
                       children: [
                         Text("${eco['payback_period_months'] ?? 60}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                         const Text("Months", style: TextStyle(color: Colors.white54))
                       ]
                     )
                   ],
                 ),
                 const SizedBox(height: 20),
                 Text(eco['message'] ?? "Investment pays itself off.", style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
               ],
             ),
           ),
           
           const SizedBox(height: 24),
           const Text("Financial Breakdown", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           _breakdownRow("Upfront Cost", eco['upfront_cost']),
           _breakdownRow("Monthly Savings", eco['monthly_savings']),
           _breakdownRow("5-Year Savings", eco['five_year_savings']),
           const Divider(color: Colors.white24),
           
           const SizedBox(height: 16),
           const Text("Financing Options", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 10),
           _financeOption("HDFC Smart Buy", "₹5,000/mo", "0% Interest"),
           _financeOption("Govt UJALA Subsidy", "- ₹8,000", "Instant Check"),
        ],
      ),
    );
  }

  Widget _buildCommunityTab(Map<String, dynamic> data) {
    final trust = Map<String, dynamic>.from(data['trust_data'] ?? {});
    final social = Map<String, dynamic>.from(data['social_proof'] ?? {});
    final guarantee = Map<String, dynamic>.from(data['guarantees'] ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: Colors.blue.withOpacity(0.1),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.blue.withOpacity(0.3))
             ),
             child: Row(
               children: [
                 const Icon(Icons.verified_user, color: Colors.blue, size: 40),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("${trust['score'] ?? 4.5}/5 ⭐ Trust Score", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       Text("Based on ${trust['verified_homes'] ?? 100} verified homes", style: const TextStyle(color: Colors.white70)),
                     ],
                   )
                 )
               ],
             ),
           ),

           const SizedBox(height: 24),
           const Text("Neighborhood Pulse", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           Container(
             height: 150,
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
               color: Colors.white10,
               borderRadius: BorderRadius.circular(16),
             ),
             child: Column(
               children: [
                 Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("📍 Gomti Nagar Live", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const Icon(Icons.rss_feed, color: Colors.greenAccent, size: 16)
                 ]),
                 const Divider(color: Colors.white24),
                Expanded(
                  child: InfiniteMarquee(
                    stepDuration: const Duration(milliseconds: 50),
                    children: [
                       Container(
                         width: 250,
                         padding: const EdgeInsets.symmetric(horizontal: 8),
                         child: Row(
                           children: const [
                             Icon(Icons.circle, size: 8, color: Colors.green),
                             SizedBox(width: 8),
                             Expanded(child: Text("Rahul installed Solar Heater", style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                             SizedBox(width: 4),
                             Text("2m ago", style: TextStyle(color: Colors.grey, fontSize: 10)),
                           ],
                         ),
                       ),
                       const SizedBox(width: 16),
                       Container(
                         width: 250,
                         padding: const EdgeInsets.symmetric(horizontal: 8),
                         child: Row(
                           children: const [
                             Icon(Icons.circle, size: 8, color: Colors.blue),
                             SizedBox(width: 8),
                             Expanded(child: Text("Priya bought Bamboo Kit", style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                             SizedBox(width: 4),
                             Text("15m ago", style: TextStyle(color: Colors.grey, fontSize: 10)),
                           ],
                         ),
                       ),
                       const SizedBox(width: 16),
                       Container(
                         width: 250,
                         padding: const EdgeInsets.symmetric(horizontal: 8),
                         child: Row(
                           children: const [
                             Icon(Icons.circle, size: 8, color: Colors.orange),
                             SizedBox(width: 8),
                             Expanded(child: Text("Amit audited Living Room", style: TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                             SizedBox(width: 4),
                             Text("1h ago", style: TextStyle(color: Colors.grey, fontSize: 10)),
                           ],
                         ),
                       ),
                       const SizedBox(width: 16),
                    ],
                  )
                )
               ],
             ),
           ),

           const SizedBox(height: 24),
           if (social['top_installer'] != null)
             ListTile(
               contentPadding: EdgeInsets.zero,
               leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
               title: Text(social['top_installer']['name'], style: const TextStyle(color: Colors.white)),
               subtitle: Text("${social['top_installer']['rating']}⭐ (${social['top_installer']['jobs']} jobs)", style: const TextStyle(color: Colors.white54)),
               trailing: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10)), child: const Text("Book")),
             ),

           const SizedBox(height: 16),
           const Divider(color: Colors.white24),
           const SizedBox(height: 16),
           
           const Text("Zero-Risk Guarantee", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           _guaranteeRow(Icons.shield, "Warranty", guarantee['warranty']),
           _guaranteeRow(Icons.price_check, "Performance", guarantee['performance']),
           _guaranteeRow(Icons.assignment_return, "Risk-Free", guarantee['risk_free']),
        ],
      ),
    );
  }

  Widget _financeOption(String name, String cost, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(sub, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          ]),
          Text(cost, style: const TextStyle(color: Colors.white))
        ],
      ),
    );
  }

  Widget _guaranteeRow(IconData icon, String title, String? desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(desc ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ))
        ],
      ),
    );
  }
  
  Widget _adviceCard(IconData icon, String title, String advice, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                     style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(advice, 
                     style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value ?? '-', style: const TextStyle(color: Colors.white))
        ],
      ),
    );
  }
  
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value ?? '-', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }

  void _showEcoStoryDialog(BuildContext context, Map<String, dynamic> data) {
    final score = Map<String, dynamic>.from(data['sustainability_score'] ?? {});
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          height: 500,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white38)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 60),
              const SizedBox(height: 20),
              const Text("EcoSnap Impact", style: TextStyle(color: Colors.white70, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text(data['product_name'] ?? 'Item', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                child: Text(score['grade'] ?? '?', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Caption copied! Ready for Instagram Stories 📸")));
                   Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text("Copy Caption & Share"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple),
              )
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(String? grade) {
    if (grade == 'A') return Colors.greenAccent;
    if (grade == 'B') return Colors.lightGreen;
    if (grade == 'C') return Colors.yellow;
    if (grade == 'D') return Colors.orange;
    return Colors.red;
  }
  
  Widget _infoCard(IconData icon, String title, String value, String subtitle) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: Colors.greenAccent, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            )
          ],
        ),
      );
    }
  Widget _impactItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
  
  Widget _minimalFeature(BuildContext context, String label, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        width: 70, // Smaller icons
        height: 70, // Cubical/Square shape
        decoration: BoxDecoration(
          color: color, 
          borderRadius: BorderRadius.circular(24), // Slightly more rounded for "iOS" feel
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center aligned
          children: [
            Icon(icon, color: Colors.black54, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                ),
              ),
            ),
          ),
          
          // Floating Voice Agent (Top Right)
          // Floating Voice Agent Removed



          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.eco, color: Colors.greenAccent, size: 28),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(text: "Eco", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                TextSpan(text: "Snap", style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24)
                        ),
                        child: Row(
                          children: [
                             const Icon(Icons.location_on, color: Colors.greenAccent, size: 14),
                             const SizedBox(width: 4),
                             Text("Mumbai", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                // Content Scroll View
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      const SizedBox(height: 10),
                      
                      // 🔥 GAMIFICATION: Daily Streak & Tips

                      const SizedBox(height: 20),

                      
                      const SizedBox(height: 20),
                      
                      // Standard Ripple Hero
                      ScanButton(
                          onTap: () {
                            print("Tap to Snap clicked!");
                            _uploadImage();
                          },
                          onLongPress: _uploadVideo,
                        ),
                        const SizedBox(height: 30),
                        
                        // SCAN MODE TOGGLE
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: ScanModeToggle(
                              currentMode: _scanMode,
                              onModeChanged: (mode) => setState(() => _scanMode = mode),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _uploadImage,
                          child: const Text(
                            "SNAP TO SEE THE GREENER SIDE",
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "(Long press for Video Audit)",
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 40),

                        // Dashboard Cards
                        Container(
                          height: 100,
                          transform: Matrix4.translationValues(0, -20, 0), // Slight overlap
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: _cardOrder.map((id) {
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: _buildCardById(id),
                              );
                            }).toList(),
                          ),
                        ),
                        

                        

                        

                        
                        const SizedBox(height: 120), // Spacing for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Navigation Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 110,
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF0F2027).withOpacity(0.95),
                    const Color(0xFF0F2027).withOpacity(0.0),
                  ],
                  stops: const [0.8, 1.0],
                ),
                border: const Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _minimalFeature(context, "Passport", Icons.card_membership, Colors.greenAccent, const ImpactPassportScreen()),
                    const SizedBox(width: 16),
                    _minimalFeature(context, "Community", Icons.public, Colors.lightBlueAccent, CommunityScreen()),
                    const SizedBox(width: 16),
                    _minimalFeature(context, "Subsidy", Icons.verified, const Color(0xFFE7C6FF), const SubsidyScreen()),
                    const SizedBox(width: 16),
                    _minimalFeature(context, "Market", Icons.storefront, const Color(0xFFBBCDE5), MarketplaceScreen()),

                    const SizedBox(width: 16),
                    _minimalFeature(context, "Backyard", Icons.agriculture, const Color(0xFFFDFFB6), const EcoFarmScreen()),
                  ],
                ),
              ),
            ),
          ),
          if (_isAnalyzing) _buildProcessingOverlay(),
        ],
      ),
    );
  }
  Widget _dashboardCard(String title, String subtitle, String action, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Minimal dark grey
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                ]
              )
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.8), size: 14),
                const SizedBox(height: 4),
                Text(action, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardById(String id) {
    switch (id) {
      case 'did_you_know':
        return _dashboardCard("Did you know?", "Switching to LEDs saves ₹200/mo.", "Details", Icons.lightbulb, Colors.yellowAccent, () {});
      case 'challenge':
        return _dashboardCard("Backyard", "Grow your digital forest.", "Visit", Icons.agriculture, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EcoFarmScreen())));
      case 'maintenance':
        return _dashboardCard("Maintenance", "Check AC Filter for efficiency.", "Check", Icons.build, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen())));
      case 'top_picks':
        return _dashboardCard("Top Picks", "Best rated eco products.", "View", Icons.star, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopPicksScreen())));
      default:
        return const SizedBox.shrink();
    }
  }

  // Dynamic Impact Card with calculated comparisons
  Widget _buildDynamicImpactCard(Map<String, dynamic> carbon) {
    // Extract CO2 value and parse it
    String co2String = carbon['total_kg_co2']?.toString() ?? '0';
    double co2Kg = double.tryParse(co2String.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    
    // Calculate dynamic comparisons
    int treesEquivalent = (co2Kg / 17).round(); // 1 tree absorbs ~17kg CO2/year
    int drivingKm = (co2Kg / 0.25).round(); // Avg car emits 0.25kg/km
    int daysOffGrid = (co2Kg / 12).round(); // Avg home uses ~12kg CO2/day
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.2))
      ),
      child: Column(
        children: [
          const Text("IMPACT PROJECTION", style: TextStyle(color: Colors.greenAccent, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("${co2Kg.toStringAsFixed(0)} kg CO₂/year", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
          const SizedBox(height: 8),
          Text("= Planting $treesEquivalent Trees 🌳", style: const TextStyle(color: Colors.green, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _impactItem(Icons.directions_car, "${(drivingKm / 1000).toStringAsFixed(1)}k km", "Driving"),
              Container(width: 1, height: 30, color: Colors.white10),
              _impactItem(Icons.power_off, "$daysOffGrid Days", "Off-Grid"),
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  // Cost of Inaction Warning Card
  Widget _buildCostOfInactionCard(Map<String, dynamic> data) {
    final eco = Map<String, dynamic>.from(data['economics'] ?? {});
    String monthlySavings = eco['monthly_savings']?.toString() ?? '₹0';
    int months = eco['payback_period_months'] ?? 24;
    
    // Calculate waste if they don't act
    double monthlyWaste = double.tryParse(monthlySavings.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    int yearlyWaste = (monthlyWaste * 12).round();
    int fiveYearWaste = (monthlyWaste * 60).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.15), Colors.orange.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 8),
              const Text("Cost of Waiting", style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "If you delay this upgrade:",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _wasteLine("1 Year", "₹${yearlyWaste.toStringAsFixed(0)}", "wasted in excess bills"),
          _wasteLine("5 Years", "₹${fiveYearWaste.toStringAsFixed(0)}", "total opportunity cost"),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Every month you wait costs you $monthlySavings in preventable waste",
                    style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                 // Navigate to Marketplace to stop the waste
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent,
                elevation: 4,
              ),
              child: const Text("STOP THE LOSS - ACT NOW", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )

        ],
      ),
    ).animate().shake(duration: 600.ms, delay: 300.ms);
  }

// ==================== GAMIFICATION & UNLOCKS ====================

bool _hasShownUnlock = false;

void _checkAndShowUnlock() {
  if (!_hasShownUnlock) {
    _hasShownUnlock = true;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D4F1C), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 25, spreadRadius: 3)
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Eco badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.greenAccent.withOpacity(0.4), Colors.transparent],
                        ),
                      ),
                    ),
                    const Icon(Icons.eco, color: Colors.greenAccent, size: 55),
                  ],
                ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 16),
                const Text("🌍 ECO IMPACT EARNED!", style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                
                const SizedBox(height: 12),
                const Text(
                  "Your scan just contributed to saving the planet!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                
                const SizedBox(height: 20),
                
                // Points earned row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _unlockStat("🌱", "+50", "Points"),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _unlockStat("💨", "0.5 kg", "CO₂ Saved"),
                      Container(width: 1, height: 40, color: Colors.white24),
                      _unlockStat("🌳", "1", "Tree Credit"),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 20),
                
                // Plant tree CTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade700, Colors.orange.shade800],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text("🪴", style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Plant a Virtual Tree!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("Your credits can grow a forest", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Maybe Later", style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EcoFarmScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Plant Now 🌱", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
      );
    });
  }
}
}





