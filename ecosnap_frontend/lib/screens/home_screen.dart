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
  
  // Order of dashboard cards
  List<String> _cardOrder = ['did_you_know', 'challenge', 'maintenance', 'top_picks'];

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
          _analysisStage = "Analyzing image structure...";
        });
        
        final contextResult = await apiService.getAnalysisQuestions(bytes, image.name, userNote: userNote);
        
        setState(() {
          _analysisProgress = 0.6;
          _analysisStage = "Extracting environmental data...";
        });

        if (mounted) {
           // 1. Force remove the overlay FIRST
           setState(() {
             _isAnalyzing = false;
             _analysisStage = "";
           });
           
           // 2. Wait for the frame to clear the overlay
           await Future.delayed(const Duration(milliseconds: 100));

           if (!mounted) return;

           final verification = contextResult['verification'] ?? {};
           final questions = contextResult['questions'] as List? ?? [];
           final detectedJourney = contextResult['journey_id'] ?? 'SPECIAL';
           
           if (_scanMode == 'quick') {
               if (mounted) setState(() => _isAnalyzing = true);
               try {
                   final answers = {
                       'journey_id': detectedJourney,
                       'user_correction': null,
                       'auto_detected': true
                   };
                   final result = await apiService.uploadImage(bytes, image.name, answers);
                   if (mounted) {
                       setState(() {
                         _isAnalyzing = false;
                         _lastAnalysisData = result;
                       });
                       if (result['type'] == 'receipt') {
                         _showCarbonAudit(result, bytes);
                       } else {
                         _showResults(result, bytes, "Quick Scan Results");
                       }
                   }
               } catch (e) {
                   if (mounted) setState(() => _isAnalyzing = false);
               }
               return; 
           }

           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => VerificationDialog(
               verificationData: verification,
               detectedJourneyId: detectedJourney,
               onResult: (isConfirmed, correctedCategory, finalJourneyId) async {
                  Navigator.pop(ctx); 
                  
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
                               if (result['type'] == 'receipt') {
                                 _showCarbonAudit(result, bytes);
                               } else {
                                 _showResults(result, bytes, "User Custom");
                               }
                           }
                         } catch (e) {
                           if (mounted) setState(() => _isAnalyzing = false);
                         }
                      },
                    )
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
    // Extracted from ReceiptScannerScreen logic
    final audit = data['carbon_audit'] ?? {
      "total_score": 82,
      "items": [
        {"name": "Organic Milk", "impact": "Low", "co2": "0.4kg"},
        {"name": "Plastic Bottled Water", "impact": "High", "co2": "2.1kg"},
        {"name": "Local Vegetables", "impact": "Very Low", "co2": "0.1kg"}
      ]
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CARBON FOOTPRINT AUDIT", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Global Insight Score", style: TextStyle(color: Colors.white70)),
                Text("${audit['total_score']}/100", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ... (audit['items'] as List).map((item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shopping_bag, color: item['impact'] == 'High' ? Colors.redAccent : Colors.greenAccent),
            title: Text(item['name'], style: const TextStyle(color: Colors.white)),
            subtitle: Text("Impact: ${item['impact']}", style: TextStyle(color: item['impact'] == 'High' ? Colors.redAccent : Colors.greenAccent, fontSize: 12)),
            trailing: Text(item['co2'], style: const TextStyle(color: Colors.white70)),
          )),
        ],
      ),
    );
  }

  void _showCarbonAudit(Map<String, dynamic> data, Uint8List imageBytes) {
     _showResults(data, imageBytes, "Implicit");
  }

  void _showResults(Map<String, dynamic> data, Uint8List imageBytes, String budget) {
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
                      length: (data['type'] == 'room') ? 3 : 7,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            labelColor: Colors.greenAccent,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.greenAccent,
                            tabs: (data['type'] == 'room') 
                              ? const [
                                  Tab(text: "Overview"),
                                  Tab(text: "Appliances"),
                                  Tab(text: "Architecture"),
                                ]
                              : const [
                                  Tab(text: "Impact"),
                                  Tab(text: "Economics"),
                                  Tab(text: "Community"),
                                  Tab(text: "Subsidies"),
                                  Tab(text: "Top Picks"),
                                  Tab(text: "Maintenance"),
                                  Tab(text: "Carbon Audit"),
                                ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: (data['type'] == 'room')
                                ? [
                                    _buildRoomOverviewTab(data),
                                    _buildRoomAppliancesTab(data),
                                    _buildGreenArchitectureTab(data),
                                  ]
                                : [
                                    _buildImpactTab(data),
                                    _buildEconomicsTab(data),
                                    _buildCommunityTab(data),
                                    const SubsidyScreen(),
                                    const TopPicksScreen(),
                                    const MaintenanceScreen(),
                                    _buildCarbonAuditView(data),
                                  ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (data['type'] == 'room')
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      // AR only works on mobile, show message on web
                      if (kIsWeb) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AR Preview is only available on mobile devices. Open this app on your phone to visualize solar panels in 3D!'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      } else {
                        // Launch Solar AR with data from analysis
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SolarARScreen(solarData: data),
                          ),
                        );
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
  }

  Widget _buildImpactTab(Map<String, dynamic> data) {
    final carbon = data['carbon_footprint'] ?? {};
    final score = data['sustainability_score'] ?? {};
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
    final eco = data['economics'] ?? {};
    
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
    final trust = data['trust_data'] ?? {};
    final social = data['social_proof'] ?? {};
    final guarantee = data['guarantees'] ?? {};

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
  
  Widget _buildRoomOverviewTab(Map<String, dynamic> data) {
    final solar = data['solar_viability'] as Map<String, dynamic>?;
    final arch = data['architectural_advice'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text("Room Audit", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                 Text("Efficiency Scan", style: TextStyle(color: Colors.grey, fontSize: 14)),
               ]),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                 child: Text("${data['sustainability_score']?['score'] ?? data['efficiency_score'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
               )
            ],
          ),
          const SizedBox(height: 24),
          _infoCard(Icons.home, "Room Rating", "${data['sustainability_score']?['score'] ?? data['efficiency_score'] ?? '0'}/100", "Based on appliances & layout"),

          if (solar != null) ...[
            const SizedBox(height: 24),
            Row(children: const [
              Icon(Icons.wb_sunny, color: Colors.orange),
              SizedBox(width: 8),
              Text("Solar Detective", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.2), Colors.red.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.5))
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                   Text(solar['is_viable'] == true ? "Viable for Solar! ☀️" : "Not Optimal ☁️", 
                     style: TextStyle(color: solar['is_viable'] == true ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                ]),
                const SizedBox(height: 8),
                Text("Potential: ${solar['potential_kw'] ?? 'N/A'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Sunlight: ${solar['sunlight_quality'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white70)),
              ]),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildRoomAppliancesTab(Map<String, dynamic> data) {
    final appliances = data['appliances'] as List? ?? [];
    final alternatives = data['alternatives'] as List? ?? [];
    
    if (appliances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.devices, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text("No appliances detected", style: TextStyle(color: Colors.white54)),
            SizedBox(height: 8),
            Text("Try scanning a room with visible appliances", 
                 style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Current Appliances", 
                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...appliances.map((app) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.power, color: Colors.orangeAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app['type'] ?? 'Appliance', 
                               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text("Current: ${app['current_power']}", 
                               style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Upgrade to: ${app['replacement']}", 
                                 style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("Saves ${app['savings_yr']}/year", 
                                 style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Recommended Upgrades", 
                       style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Based on your room analysis", 
                 style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildGreenArchitectureTab(Map<String, dynamic> data) {
    final architecture = data['architectural_advice'] ?? {};
    final solar = data['solar_viability'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solar Viability Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.3))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    const Text("Solar Detective", 
                               style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                if (solar['is_viable'] == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.black, size: 16),
                        SizedBox(width: 6),
                        Text("Viable for Solar!", 
                             style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow("Potential", solar['potential_kw']),
                  _infoRow("Sunlight Quality", solar['sunlight_quality']),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      solar['recommendation'] ?? 'Good solar potential detected',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ] else ...[
                  const Text("Not ideal for solar panels", 
                             style: TextStyle(color: Colors.white54)),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text("Architectural Advice", 
                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (architecture['layout_optimization'] != null)
            _adviceCard(
              Icons.space_dashboard,
              "Layout Optimization",
              architecture['layout_optimization'],
              Colors.blue,
            ),
          
          const SizedBox(height: 12),
          
          if (architecture['ventilation_tip'] != null)
            _adviceCard(
              Icons.air,
              "Ventilation",
              architecture['ventilation_tip'],
              Colors.cyan,
            ),
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
    final score = data['sustainability_score'] ?? {};
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
                             Text("Home", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
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
                    _minimalFeature(context, "Community", Icons.public, Colors.lightBlueAccent, CommunityScreen()),
                    const SizedBox(width: 16),
                    _minimalFeature(context, "Subsidy", Icons.verified, const Color(0xFFE7C6FF), const SubsidyScreen()),
                    const SizedBox(width: 16),
                    _minimalFeature(context, "Market", Icons.storefront, const Color(0xFFBBCDE5), MarketplaceScreen()),
                    const SizedBox(width: 16),
                    _minimalFeature(context, "Carbon", Icons.cloud, const Color(0xFFFFC6FF), CarbonScreen()),
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
    final eco = data['economics'] ?? {};
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
        ],
      ),
    ).animate().shake(duration: 600.ms, delay: 300.ms);
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

  // Calculate payback progress (shorter = better = higher progress)
  double _calculatePaybackProgress(dynamic months) {
    int paybackMonths = months is int ? months : (int.tryParse(months?.toString() ?? '60') ?? 60);
    // Inverse relationship: 12 months = 100%, 60 months = 20%
    return (1.0 - (paybackMonths.clamp(0, 60) / 60)).clamp(0.2, 1.0);
  }

}

