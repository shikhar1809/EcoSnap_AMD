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
import 'impact_passport_screen.dart';
import '../widgets/questionnaire_dialog.dart';
import 'top_picks_screen.dart';
import '../widgets/voice_agent_widget.dart';
import '../widgets/infinite_marquee.dart';
import '../widgets/verification_dialog.dart';
import 'furniture_ar_screen.dart';
import 'land_ar_screen.dart';
import 'solar_ar_screen.dart';
import 'aadhaar_verification_screen.dart';
import 'eco_farm_screen.dart';
import '../widgets/scan_button.dart';

import 'location_picker_screen.dart'; // NEW import
import 'package:google_maps_flutter/google_maps_flutter.dart'; // For LatLng
import 'room_ar_screen.dart'; // NEW import
import 'wind_ar_screen.dart'; // NEW import

import '../widgets/ryzen_ai_toggle.dart'; // NEW import

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
      if (mounted) {
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
        
        // NEW: Location Prompt ONLY for Solar/Wind Scans
        double? lat, lng;
        final detectedJourney = contextResult['journey_id'] ?? 'SPECIAL';
        
        // Only ask for location if it's relevant (Solar/Wind/Land) and in Deep mode
        bool isLocationRelevant = ['SOLAR_AUDIT', 'WIND_ANALYSIS', 'LAND_ANALYSIS'].contains(detectedJourney);

        if (isLocationRelevant && mounted) {
           bool wantLocation = await showDialog(
             context: context,
             builder: (ctx) => AlertDialog(
               backgroundColor: Colors.grey.shade900,
               title: const Text("Enhance Accuracy?", style: TextStyle(color: Colors.white)),
               content: const Text("Add your precise location for accurate Solar & Wind potential analysis (Google Maps 3D).", style: TextStyle(color: Colors.white70)),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Skip")),
                 TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Add Location", style: TextStyle(color: Colors.greenAccent))),
               ],
             )
           ) ?? false;

           if (wantLocation && mounted) {
              final LatLng? picked = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationPickerScreen())
              );
              if (picked != null) {
                lat = picked.latitude;
                lng = picked.longitude;
              }
           }
        }

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

           final verification = Map<String, dynamic>.from(contextResult['verification'] ?? {});
           final questions = (contextResult['questions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
           // detectedJourney is already defined above



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
                           print('[HOME] DEBUG: Starting Deep Analysis Logic');
                           if (correctedCategory != null) {
                             answers['user_correction'] = correctedCategory;
                           }
                           answers['journey_id'] = finalJourneyId;
                           
                           print('[HOME] Calling API uploadImage...');
                           final result = await apiService.uploadImage(bytes, image.name, answers, latitude: lat, longitude: lng);
                           print('[HOME] API Result keys: ${result.keys}');
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
                           print('[HOME] Deep Analysis Error: $e');
                           if (mounted) {
                               setState(() => _isAnalyzing = false);
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                           }
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
    final tabs = _getTabs(data);
    final tabViews = _getTabViews(data);
    bool showDepthMap = false;
    bool showThermalMap = false;
    
    Uint8List? depthBytes;
    if (data['depth_map'] != null) {
      try {
        depthBytes = base64Decode(data['depth_map']);
      } catch (e) {
        debugPrint("Failed to decode depth map: $e");
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: showDepthMap && depthBytes != null
                                ? Image.memory(depthBytes!, fit: BoxFit.cover)
                                : showThermalMap
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ColorFiltered(
                                            colorFilter: const ColorFilter.mode(Colors.deepPurple, BlendMode.colorDodge),
                                            child: Image.memory(imageBytes, fit: BoxFit.cover),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                colors: [Colors.blueAccent.withOpacity(0.6), Colors.transparent, Colors.deepOrange.withOpacity(0.4)],
                                                stops: const [0.2, 0.6, 1.0],
                                                center: const Alignment(0.5, 0.2), // Simulated cold leak point
                                                radius: 0.8,
                                              )
                                            ),
                                          )
                                        ],
                                      )
                                    : Image.memory(imageBytes, fit: BoxFit.cover),
                          ),
                        ),
                        if (depthBytes != null)
                          Positioned(
                            top: 16, right: 16,
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() => showDepthMap = !showDepthMap);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: showDepthMap ? Colors.blueAccent : Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24)
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(showDepthMap ? Icons.layers_clear : Icons.layers, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(showDepthMap ? "Hide Depth Map" : "View Depth Map", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (data['type'] == 'room_interior')
                          Positioned(
                            top: 16, left: 16,
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  showThermalMap = !showThermalMap;
                                  if (showThermalMap) showDepthMap = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: showThermalMap ? Colors.deepOrange : Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24)
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(showThermalMap ? Icons.thermostat : Icons.thermostat_outlined, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(showThermalMap ? "Hide IR Thermal" : "Thermal Leak Map", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                    
                    Expanded(
                      child: DefaultTabController(
                        length: tabs.length,
                        child: Column(
                          children: [
                            TabBar(
                              isScrollable: true,
                              labelColor: Colors.greenAccent,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.greenAccent,
                              tabs: tabs,
                            ),
                            Expanded(
                              child: TabBarView(
                                children: tabViews,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (data['type'] == 'room_interior' || data['type'] == 'property_exterior' || data['type'] == 'land_plot' || data['journey'] == 'WIND_ANALYSIS' || data['journey'] == 'SOLAR_AUDIT' || data['journey'] == 'LAND_ANALYSIS')
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              if (data['type'] == 'room_interior') return RoomARScreen(roomData: data, imageBytes: imageBytes);
                              if (data['journey'] == 'WIND_ANALYSIS') return WindARScreen(windData: data, imageBytes: imageBytes);
                              if (data['journey'] == 'LAND_ANALYSIS' || data['type'] == 'land_plot') return LandARScreen(landData: data, imageBytes: imageBytes);
                              return SolarARScreen(solarData: data, imageBytes: imageBytes);
                            }
                          ),
                        );
                      },
                      label: const Text("AR PREVIEW", style: TextStyle(fontWeight: FontWeight.bold)),
                      icon: const Icon(Icons.view_in_ar),
                      backgroundColor: data['type'] == 'room_interior' ? Colors.blueAccent : (data['journey'] == 'WIND_ANALYSIS' ? Colors.cyan : (data['journey'] == 'LAND_ANALYSIS' || data['type'] == 'land_plot' ? Colors.green : Colors.orangeAccent)),
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
      ),
    );
  }



  // ==========================================
  // SCAN TAB BUILDERS
  // ==========================================

  List<Widget> _getTabs(Map<String, dynamic> data) {
    if (data['type'] == 'room_interior') {
      return const [Tab(text: "Overview"), Tab(text: "Appliances"), Tab(text: "Architecture")];
    }
    if (data['journey'] == 'WIND_ANALYSIS') {
      return const [Tab(text: "Wind Potential"), Tab(text: "Installation"), Tab(text: "Financials")];
    }
    if (data['type'] == 'property_exterior' || data['journey'] == 'SOLAR_AUDIT') {
      return const [Tab(text: "Solar Potential"), Tab(text: "ROI & Subsidies"), Tab(text: "Installation")];
    }
    if (data['journey'] == 'PRODUCT_SCAN') {
      return const [Tab(text: "Lifecycle"), Tab(text: "Material"), Tab(text: "Alternatives")];
    }
    if (data['journey'] == 'BILL_OCR') {
      return const [Tab(text: "Bill Details"), Tab(text: "Analysis"), Tab(text: "Savings Tips")];
    }
    if (data['journey'] == 'FOOD_AUDIT') {
      return const [Tab(text: "Carbon Footprint"), Tab(text: "Green Swaps"), Tab(text: "Food Miles")];
    }
    if (data['journey'] == 'VEHICLE_CHECK') {
      return const [Tab(text: "Emissions"), Tab(text: "EV Switch"), Tab(text: "Savings")];
    }
    if (data['journey'] == 'LAND_ANALYSIS' || data['type'] == 'land_plot') {
      return const [
        Tab(text: 'Land Profile'),
        Tab(text: 'Solar Farm'),
        Tab(text: 'Agrivoltaic'),
        Tab(text: 'Financials'),
      ];
    }
    // Fallback 'SPECIAL' or others
    return const [
       Tab(text: "Impact"),
       Tab(text: "Economics"), 
       Tab(text: "Community")
    ];
  }

  List<Widget> _getTabViews(Map<String, dynamic> data) {
    if (data['type'] == 'room_interior') {
      return [
        _buildRoomOverviewTab(data),
        _buildRoomAppliancesTab(data),
        _buildGreenArchitectureTab(data),
      ];
    }
    if (data['journey'] == 'LAND_ANALYSIS' || data['type'] == 'land_plot') {
      return [
        _buildLandProfileTab(data),
        _buildLandSolarTab(data),
        _buildLandAgriTab(data),
        _buildLandFinancialsTab(data),
      ];
    }
    if (data['journey'] == 'WIND_ANALYSIS') {
      return [
        _buildWindAnalysisTab(data),
        _buildWindInstallationTab(data), // NEW: Dedicated Wind Installation
        _buildWindEconomicsTab(data), // NEW: Dedicated Wind Financials
      ];
    }
    if (data['type'] == 'property_exterior' || data['journey'] == 'SOLAR_AUDIT') {
       return [
        _buildSolarPotentialTab(data),
        _buildSolarEconomicsTab(data),
        _buildSolarInstallationTab(data),
      ];
    }
    if (data['journey'] == 'PRODUCT_SCAN') {
      return [
        _buildProductLifecycleTab(data),
        _buildMaterialTab(data),
        _buildAlternativesTab(data),
      ];
    }
    if (data['journey'] == 'BILL_OCR') {
      return [
        _buildBillDetailsTab(data),
        _buildBillAnalysisTab(data),
        _buildBillSavingsTab(data),
      ];
    }
    if (data['journey'] == 'FOOD_AUDIT') {
      return [
        _buildFoodImpactTab(data),
        _buildFoodSwapsTab(data),
        _buildFoodMilesTab(data),
      ];
    }
    if (data['journey'] == 'VEHICLE_CHECK') {
      return [
        _buildVehicleEmissionsTab(data),
        _buildEVSwitchTab(data),
        _buildVehicleSavingsTab(data),
      ];
    }
    
    // Fallback
    return [
      _buildImpactTab(data),
      _buildEconomicsTab(data),
      _buildCommunityTab(data),
    ];
  }

  // ==========================================
  // LAND ANALYSIS SPECIFIC WIDGETS
  // ==========================================

  Widget _buildLandProfileTab(Map<String, dynamic> data) {
    final lp = data['land_profile'] as Map? ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terrain summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.terrain, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(lp['land_type'] ?? 'Agricultural Land', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat('${(lp['estimated_area_acres'] ?? 2.5).toStringAsFixed(1)}', 'acres', Colors.greenAccent),
                    _miniStat('${lp['terrain_slope_deg'] ?? '~5'}°', 'slope', Colors.amberAccent),
                    _miniStat(lp['soil_type'] ?? 'Loamy', 'soil', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _infoRow('Vegetation Cover', lp['vegetation_cover'] ?? 'Sparse'),
          _infoRow('Drainage Quality', lp['drainage_quality'] ?? 'Good'),
          _infoRow('Nearest Obstruction', '${lp['nearest_obstruction_m'] ?? 50} m'),
          const SizedBox(height: 20),
          _infoCard(Icons.info_outline, 'Land Suitability', 'High', 'Suitable for ground-mounted solar or agrivoltaic installation based on terrain analysis.'),
        ],
      ),
    );
  }

  Widget _buildLandSolarTab(Map<String, dynamic> data) {
    final sp = data['solar_potential'] as Map? ?? {};
    final wp = data['wind_potential'] as Map? ?? {};
    final viability = (sp['viability_score'] as num?)?.toInt() ?? 78;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard(Icons.wb_sunny, 'Solar Score', '$viability/100', sp['recommended_system'] ?? 'Ground-Mount Fixed Tilt'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amberAccent.withOpacity(0.3))),
            child: Column(
              children: [
                const Text('ANNUAL ENERGY OUTPUT', style: TextStyle(color: Colors.amberAccent, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 12),
                Text('${sp['estimated_annual_generation_kwh'] ?? 150000} kWh', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${sp['estimated_capacity_kw'] ?? 100} kW system · ${sp['land_utilization_percent'] ?? 40}% land utilized', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Shading Risk', sp['shading_risk'] ?? 'Low'),
          _infoRow('Wind Capacity', '${wp['estimated_capacity_kw'] ?? 50} kW'),
          _infoRow('Wind Score', '${wp['viability_score'] ?? 65}/100'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.eco, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(data['recommendation'] ?? 'Ground-mounted solar is highly viable for this land.', style: const TextStyle(color: Colors.white70, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildLandAgriTab(Map<String, dynamic> data) {
    final agri = data['agrivoltaic_potential'] as Map? ?? {};
    final crops = (agri['compatible_crops'] as List?) ?? ['Wheat', 'Vegetables', 'Spices'];
    final feasible = agri['feasible'] as bool? ?? true;
    final yieldImpact = agri['yield_impact_percent'] ?? -15;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: feasible
                  ? LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)])
                  : LinearGradient(colors: [Colors.red.withOpacity(0.1), Colors.transparent]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (feasible ? Colors.greenAccent : Colors.redAccent).withOpacity(0.4)),
            ),
            child: Row(children: [
              Icon(feasible ? Icons.check_circle : Icons.cancel, color: feasible ? Colors.greenAccent : Colors.redAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(feasible ? '✅ Agrivoltaic Feasible' : '❌ Not Recommended', style: TextStyle(color: feasible ? Colors.greenAccent : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(agri['panel_configuration'] ?? 'Elevated 3m+ panels', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Compatible Crops', style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: crops.map<Widget>((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.greenAccent.withOpacity(0.3))),
              child: Text('🌱 $c', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
            )).toList(),
          ),
          const SizedBox(height: 20),
          _infoRow('Yield Impact', '$yieldImpact% (with panels)'),
          _infoRow('Dual Income', agri['dual_income_potential'] ?? 'High'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amberAccent.withOpacity(0.2))),
            child: const Text('💡 Agrivoltaic systems increase land productivity by combining solar generation with crop cultivation — ideal for farmers.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildLandFinancialsTab(Map<String, dynamic> data) {
    final fin = data['financial_analysis'] as Map? ?? {};
    final schemes = (fin['government_schemes'] as List?) ?? ['PM-KUSUM', 'SECI Tenders', 'Net Metering'];
    final clearing = data['land_clearing_requirements'] as Map? ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.18), Colors.green.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Column(children: [
              const Text('25-YEAR PROFIT', style: TextStyle(color: Colors.greenAccent, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 10),
              Text('₹${_formatNum(((fin['25_year_profit_inr'] as num?)?.toInt() ?? 8500000))}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Payback: ${fin['payback_years'] ?? 7} years', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 16),
          _infoRow('Project Cost', '₹${_formatNum(((fin['solar_farm_project_cost_inr'] as num?)?.toInt() ?? 5000000))}'),
          _infoRow('Annual Revenue', '₹${_formatNum(((fin['estimated_annual_revenue_inr'] as num?)?.toInt() ?? 450000))}'),
          _infoRow('Vegetation Removal', clearing['vegetation_removal_needed'] == true ? 'Required' : 'Not Required'),
          _infoRow('Grading Required', clearing['grading_required'] == true ? 'Yes' : 'No'),
          _infoRow('Preparation Cost', '₹${_formatNum(((clearing['estimated_preparation_cost_inr'] as num?)?.toInt() ?? 80000))}'),
          const SizedBox(height: 20),
          const Align(alignment: Alignment.centerLeft, child: Text('Government Schemes', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          ...schemes.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amberAccent.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.account_balance, color: Colors.amberAccent, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(s.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))),
            ]),
          )),
        ],
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toString();
  }

  Widget _miniStat(String val, String label, Color color) {
    return Column(children: [
      Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ]);
  }

  // ==========================================
  // WIND ANALYSIS SPECIFIC WIDGETS
  // ==========================================

  Widget _buildWindInstallationTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    // Backend key: 'installation_feasibility'
    final install = Map<String, dynamic>.from(data['installation_feasibility'] as Map? ?? {});

    if (install.isEmpty) return const Center(child: Text("No Installation Data", style: TextStyle(color: Colors.white)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(Icons.build, "Feasibility", install['structural_integrity'] ?? 'Unknown', "Structural Assessment"),
          const SizedBox(height: 20),
          _infoRow("Noise Impact", install['noise_impact_risk'] ?? '-'),
          _infoRow("Safety Radius", "${install['safety_zone_radius_m'] ?? '-'} m"),
          
          const SizedBox(height: 24),
          const Text("Placement Advice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Icon(Icons.info_outline, color: Colors.cyanAccent),
                 const SizedBox(width: 12),
                 Expanded(child: Text(data['recommendation'] ?? "Ensure turbine is mounted above turbulent air flow (at least 3m above roof line).", style: const TextStyle(color: Colors.white70)))
               ]
            ),
          )
        ],
      ),
    );
  }

  Widget _buildWindEconomicsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final fin = Map<String, dynamic>.from(data['financial_analysis'] as Map? ?? {});
    final systemCost = (fin['system_cost_estimate_inr'] as num?)?.toInt() ?? 0;
    final roiPercent = (fin['roi_percent'] as num?)?.toDouble() ?? 0;
    final paybackYears = (fin['payback_period_years'] as num?)?.toDouble() ?? 0;

    if (fin.isEmpty) return const Center(child: Text("No Financial Data", style: TextStyle(color: Colors.white)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROI Hero Ring
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green.withOpacity(0.12), Colors.teal.withOpacity(0.06)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Column(children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120, height: 120,
                      child: CircularProgressIndicator(
                        value: (roiPercent / 100).clamp(0, 1),
                        strokeWidth: 10,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(roiPercent > 15 ? Colors.greenAccent : roiPercent > 8 ? Colors.amber : Colors.redAccent),
                      ),
                    ),
                    Column(children: [
                      Text("${roiPercent.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                      const Text("ROI", style: TextStyle(color: Colors.white54, fontSize: 11)),
                    ]),
                  ],
                ).animate().scale(duration: 600.ms, begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
                const SizedBox(height: 10),
                const Text("Annual Return on Investment", style: TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // System Cost & Payback
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _solarSpecCard("₹${_formatNum(systemCost)}", "System Cost", Icons.paid, Colors.amber)),
            const SizedBox(width: 10),
            Expanded(child: _solarSpecCard("${paybackYears.toStringAsFixed(1)} yr", "Payback", Icons.timer, Colors.cyan)),
          ]).animate().fadeIn(delay: 200.ms),

          // Payback Bar
          if (paybackYears > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Payback Progress", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(paybackYears < 5 ? "⚡ Fast" : paybackYears < 10 ? "Good" : "Long", style: TextStyle(color: paybackYears < 5 ? Colors.greenAccent : Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (1 - paybackYears / 15).clamp(0, 1),
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(paybackYears < 5 ? Colors.greenAccent : Colors.amber),
                    minHeight: 8,
                  ),
                ),
              ]),
            ).animate().fadeIn(delay: 300.ms),
          ],

          // Download
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text("Download Detailed Report", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
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
                    Text(data['product_name'] ?? data['building_type'] ?? data['property_type'] ?? data['item_name'] ?? data['message'] ?? 'Analysis Complete', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(data['condition_assessment'] ?? 'Analysis Complete', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 12),
                      const SizedBox(width: 4),
                      Text("AI Estimate • ${((data['confidence_score'] ?? data['_metadata']?['confidence_score'] ?? 0.85) * 100).toInt()}% Confidence", 
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
  
  Widget _buildRoomOverviewTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final room3d = data['room_3d_analysis'] != null ? Map<String, dynamic>.from(data['room_3d_analysis'] as Map) : null;
    final thermal = data['thermal_analysis'] != null ? Map<String, dynamic>.from(data['thermal_analysis'] as Map) : null;
    final vampire = data['vampire_power_analysis'] != null ? Map<String, dynamic>.from(data['vampire_power_analysis'] as Map) : null;
    final acSizing = data['ac_sizing_analysis'] != null ? Map<String, dynamic>.from(data['ac_sizing_analysis'] as Map) : null;
    final lighting = data['lighting_analysis'] != null ? Map<String, dynamic>.from(data['lighting_analysis'] as Map) : null;
    final quickWins = data['quick_wins'] as List? ?? [];
    final effScore = data['sustainability_score']?['score'] ?? data['efficiency_score'] ?? 0;
    final totalSavings = data['total_potential_savings_annual'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Efficiency Score Header ─────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _getEfficiencyColor(effScore is int ? effScore : 0).withOpacity(0.25),
                Colors.black12,
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getEfficiencyColor(effScore is int ? effScore : 0).withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Room Energy Audit", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (room3d != null) Text(
                    "${room3d['room_type'] ?? 'Room'} • ${room3d['estimated_length_m'] ?? '?'}m × ${room3d['estimated_width_m'] ?? '?'}m × ${room3d['estimated_height_m'] ?? '?'}m",
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  if (totalSavings != null) Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("💰 Save up to ₹$totalSavings/year", style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ])),
                Container(
                  width: 60, height: 60, alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _getEfficiencyColor(effScore is int ? effScore : 0),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _getEfficiencyColor(effScore is int ? effScore : 0).withOpacity(0.5), blurRadius: 16)],
                  ),
                  child: Text("$effScore", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
                ),
              ],
            ),
          ),

          // ── 3D Room Dimensions ─────────────────────
          if (room3d != null) ...[
            const SizedBox(height: 20),
            Row(children: const [Icon(Icons.straighten, color: Colors.cyanAccent, size: 18), SizedBox(width: 6), Text("Room Dimensions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _miniStatRoom("📐 Volume", "${room3d['volume_m3'] ?? '?'} m³")),
              const SizedBox(width: 8),
              Expanded(child: _miniStatRoom("🪟 Windows", "${room3d['window_count'] ?? '?'}")),
              const SizedBox(width: 8),
              Expanded(child: _miniStatRoom("🧭 Facing", "${room3d['window_orientation'] ?? '?'}")),
            ]),
          ],

          // ── Thermal Analysis ───────────────────────
          if (thermal != null) ...[
            const SizedBox(height: 20),
            Row(children: const [Icon(Icons.thermostat, color: Colors.redAccent, size: 18), SizedBox(width: 6), Text("Thermal Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("${thermal['wall_material'] ?? 'Unknown'} walls • ${thermal['window_type'] ?? 'Unknown'} glass", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: thermal['insulation_quality'] == 'Excellent' ? Colors.green : (thermal['insulation_quality'] == 'Good' ? Colors.orange : Colors.red), borderRadius: BorderRadius.circular(6)),
                    child: Text("${thermal['insulation_quality'] ?? '?'}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 8),
                if (thermal['estimated_heat_gain_watts'] != null)
                  Text("🔥 Heat Gain: ${thermal['estimated_heat_gain_watts']}W", style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                if (thermal['thermal_comfort_score'] != null)
                  Padding(padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Text("Comfort: ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (thermal['thermal_comfort_score'] as num) / 100, backgroundColor: Colors.white12, color: Colors.cyanAccent, minHeight: 6))),
                      const SizedBox(width: 6),
                      Text("${thermal['thermal_comfort_score']}%", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                    ]),
                  ),
              ]),
            ),
          ],

          // ── AC Sizing Alert ────────────────────────
          if (acSizing != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: acSizing['sizing_status'] == 'Optimal' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: acSizing['sizing_status'] == 'Optimal' ? Colors.greenAccent.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Row(children: [
                Icon(acSizing['sizing_status'] == 'Optimal' ? Icons.check_circle : Icons.warning_amber, color: acSizing['sizing_status'] == 'Optimal' ? Colors.greenAccent : Colors.orangeAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("AC: ${acSizing['sizing_status'] ?? 'Unknown'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Need ${acSizing['required_capacity_ton'] ?? '?'}T • Have ${acSizing['current_capacity_ton'] ?? '?'}T", style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  if (acSizing['annual_waste_inr'] != null && acSizing['annual_waste_inr'] != 0)
                    Text("⚠️ Wasting ₹${acSizing['annual_waste_inr']}/year", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ])),
              ]),
            ),
          ],

          // ── Vampire Power Alert ────────────────────
          if (vampire != null && vampire['total_standby_watts'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.purpleAccent.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text("🧛", style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Text("Vampire Power", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Text("${vampire['total_standby_watts']}W standby", style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text("💸 ₹${vampire['annual_cost_inr'] ?? '?'}/year wasted on standby", style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                if (vampire['smart_plug_recommendation'] == true) ...[
                  const SizedBox(height: 6),
                  Text("💡 Smart plugs pay for themselves in ${vampire['smart_plug_roi_months'] ?? '?'} months", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
                if (vampire['devices'] != null) ...[
                  const SizedBox(height: 8),
                  ...((vampire['devices'] as List).take(3).map((d) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text("  • ${d['device'] ?? '?'}: ${d['watts'] ?? '?'}W (₹${d['annual_cost'] ?? '?'}/yr)", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ))),
                ],
              ]),
            ),
          ],

          // ── Lighting Analysis ──────────────────────
          if (lighting != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.amber.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [const Icon(Icons.lightbulb, color: Colors.amber, size: 20), const SizedBox(width: 8), const Text("Lighting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]),
                const SizedBox(height: 8),
                if (lighting['bulb_types'] != null)
                  Text("💡 ${lighting['bulb_count'] ?? '?'} bulbs: LED(${lighting['bulb_types']?['LED'] ?? 0}) CFL(${lighting['bulb_types']?['CFL'] ?? 0}) Old(${lighting['bulb_types']?['Incandescent'] ?? 0})", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                if (lighting['led_conversion_savings'] != null)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text("🔄 LED upgrade saves ₹${lighting['led_conversion_savings']}/yr", style: const TextStyle(color: Colors.greenAccent, fontSize: 12))),
                if (lighting['natural_light_score'] != null) Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Text("☀️ Natural Light: ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (lighting['natural_light_score'] as num) / 100, backgroundColor: Colors.white12, color: Colors.amber, minHeight: 6))),
                    const SizedBox(width: 6),
                    Text("${lighting['natural_light_score']}%", style: const TextStyle(color: Colors.amber, fontSize: 11)),
                  ]),
                ),
              ]),
            ),
          ],

          // ── Quick Wins ─────────────────────────────
          if (quickWins.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(children: const [Icon(Icons.bolt, color: Colors.greenAccent, size: 18), SizedBox(width: 6), Text("Quick Wins", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 10),
            ...quickWins.take(4).map((w) {
              final win = w is Map ? Map<String, dynamic>.from(w) : <String, dynamic>{};
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(win['action'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 13))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text("₹${win['annual_savings'] ?? '?'}/yr", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text("${win['payback_months'] ?? '?'}mo payback", style: const TextStyle(color: Colors.white38, fontSize: 9)),
                  ]),
                ]),
              );
            }),
          ],

          // ── Recommendation ─────────────────────────
          if (data['recommendation'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(data['recommendation'], style: const TextStyle(color: Colors.white70, fontSize: 13))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Color _getEfficiencyColor(int score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  Widget _miniStatRoom(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Widget _buildRoomAppliancesTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    // Prefer the new detailed 'detected_appliances' array format, fallback to legacy 'appliances'
    final List<dynamic> rawApps = data['detected_appliances'] ?? data['appliances'] ?? [];
    final appliances = rawApps.map((e) => Map<String, dynamic>.from(e as Map? ?? {})).toList();
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
            Text("Try scanning a room with visible appliances", style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Detected Appliances", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...appliances.map((app) {
            final String name = app['name'] ?? app['type'] ?? 'Unknown Appliance';
            final String power = app['estimated_power_watts'] != null ? "${app['estimated_power_watts']}W" : (app['current_power'] ?? '');
            final String cost = app['monthly_cost_inr'] != null ? "₹${app['monthly_cost_inr']}/mo" : '';
            final String eff = app['estimated_star_rating'] ?? app['efficiency_rating'] ?? '';
            final String placement = app['placement_efficiency'] ?? '';
            final List issues = app['efficiency_issues'] ?? [];
            final String upgrade = app['upgrade_suggestion'] ?? app['replacement'] ?? '';
            final String savings = app['potential_savings_inr'] != null ? "₹${app['potential_savings_inr']}/yr" : (app['savings_yr'] ?? '');
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: placement == 'Poor' ? Colors.redAccent.withOpacity(0.3) : Colors.white12)
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
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Row(children: [
                              if (power.isNotEmpty) Text("🔌 $power", style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                              if (power.isNotEmpty && cost.isNotEmpty) const Text(" • ", style: TextStyle(color: Colors.white38, fontSize: 11)),
                              if (cost.isNotEmpty) Text("💸 $cost", style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                            ]),
                          ],
                        ),
                      ),
                      if (eff.isNotEmpty && eff != 'Unknown')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: Text(eff.contains('Star') || eff.contains('star') ? eff : "$eff Star", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  
                  if (app['placement'] != null) ...[
                    const SizedBox(height: 12),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.location_on, color: Colors.cyanAccent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(child: Text("Location: ${app['placement']} (${placement})", style: TextStyle(color: placement == 'Poor' ? Colors.redAccent : Colors.cyanAccent, fontSize: 12))),
                    ]),
                  ],

                  if (issues.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...issues.map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("⚠️ ", style: TextStyle(fontSize: 12)),
                        Expanded(child: Text(issue.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ]),
                    )),
                  ],

                  if (upgrade.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upgrade, color: Colors.greenAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(upgrade, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                if (savings.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text("Saves $savings", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (alternatives.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Recommended Upgrades", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Based on your room analysis", style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildWindAnalysisTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    // ADAPTED: Backend calls it 'wind_potential', frontend previously looked for 'wind_analysis'
    final wind = Map<String, dynamic>.from(data['wind_potential'] as Map? ?? {});
    final site = Map<String, dynamic>.from(data['site_analysis'] as Map? ?? {});
    final location = Map<String, dynamic>.from(data['location_data'] as Map? ?? {});

    if (wind.isEmpty) {
        return const Center(child: Text("No Wind Data Available", style: TextStyle(color: Colors.white)));
    }

    // Mapping backend simplified score (0-100) to UI 'suitability' label
    final int score = wind['viability_score'] ?? 0;
    final String suitability = score > 70 ? 'High' : (score > 40 ? 'Medium' : 'Low');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               gradient: LinearGradient(colors: [Colors.blueAccent.withOpacity(0.2), Colors.cyanAccent.withOpacity(0.1)]),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                   const Text("Wind Potential", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text("Score: $score/100 • ${wind['recommended_turbine_type'] ?? 'Turbine Analysis'}", 
                        style: const TextStyle(color: Colors.white54, fontSize: 10)),
                 ]),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: suitability == 'High' ? Colors.green : (suitability == 'Medium' ? Colors.orange : Colors.red), borderRadius: BorderRadius.circular(12)),
                   child: Text(suitability, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                 )
               ],
             ),
           ),
           const SizedBox(height: 24),
           
           _infoCard(Icons.air, "Flow Quality", site['flow_quality'] ?? 'Unknown', "Based on detected obstacles"),
           const SizedBox(height: 12),
           
           Row(children: [
             Expanded(child: _infoCard(Icons.height, "Hub Height", "${site['estimated_hub_height_m'] ?? '-'} m", "Est. Mounting Point")),
             const SizedBox(width: 12),
             Expanded(child: _infoCard(Icons.flash_on, "Est. Power", "${wind['estimated_annual_generation_kwh'] ?? '-'} kWh", "Annual Output")),
           ]),

           const SizedBox(height: 24),
           const Text("Turbine Recommendation", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
             child: Column(
               children: [
                 const Icon(Icons.wind_power, color: Colors.cyanAccent, size: 40),
                 const SizedBox(height: 12),
                 Text(suitability == 'High' 
                      ? "Excellent conditions! A ${wind['recommended_turbine_type']} is strongly recommended."
                      : "Wind potential is ${suitability.toLowerCase()}. Consider a Hybrid (Solar + Wind) system for reliability.",
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildSolarPotentialTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final solar = Map<String, dynamic>.from(data['solar_potential'] as Map? ?? {});
    final roof = Map<String, dynamic>.from(data['roof_3d_analysis'] as Map? ?? {});
    final zones = (data['panel_placement_zones'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map? ?? {})).toList();
    
    // Safely parse values
    int viabilityScore = (solar['viability_score'] as num?)?.toInt() ?? 0;
    String totalArea = _safeParseNumStr(roof['estimated_area_sqm'], '—');
    String usableArea = _safeParseNumStr(roof['usable_area_sqm'], '—');
    String tiltAngle = _safeParseNumStr(roof['tilt_angle_degrees'], '—');
    String orientation = roof['orientation']?.toString() ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Viability Score Ring
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.12), Colors.orange.withOpacity(0.06)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: viabilityScore / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(viabilityScore > 70 ? Colors.greenAccent : viabilityScore > 40 ? Colors.amber : Colors.redAccent),
                    ),
                  ),
                  Column(children: [
                    Text("$viabilityScore", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text("Viability", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                ],
              ).animate().scale(duration: 600.ms, begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Roof Spec Cards
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _solarSpecCard(totalArea != '—' ? totalArea : '—', "Total Area (m²)", Icons.aspect_ratio, Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _solarSpecCard(usableArea != '—' ? usableArea : '—', "Usable Area (m²)", Icons.dashboard, Colors.greenAccent)),
          ]).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _solarSpecCard(tiltAngle != '—' ? "$tiltAngle°" : '—', "Tilt Angle", Icons.straighten, Colors.amber)),
            const SizedBox(width: 10),
            Expanded(child: _solarSpecCard(orientation, "Orientation", Icons.explore, Colors.blueAccent)),
          ]).animate().fadeIn(delay: 300.ms),

          // Panel Placement Zones
          if (zones.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Panel Placement Zones", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...zones.asMap().entries.map((entry) {
              final z = entry.value;
              final idx = entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32, alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text("${z['zone_id'] ?? idx + 1}", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${z['panel_count'] ?? '—'} Panels · ${z['orientation'] ?? ''}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("Priority: ${z['priority'] ?? '—'}", style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  )),
                  Text("${z['annual_generation_kwh'] ?? '—'} kWh", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ).animate().fadeIn(delay: (300 + idx * 100).ms).slideX(begin: 0.05, end: 0);
            }),
          ],
        ],
      ),
    );
  }

  Widget _solarSpecCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  String _safeParseNumStr(dynamic val, String fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toInt().toString();
    final str = val.toString();
    final match = RegExp(r'[0-9]+').firstMatch(str);
    if (match != null) return match.group(0)!;
    return fallback;
  }

  Widget _buildSolarEconomicsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final fin = Map<String, dynamic>.from(data['financial_analysis'] as Map? ?? {});
    
    // Dynamic parsing
    final netInvestment = int.tryParse(_safeParseNumStr(fin['net_investment'], '0')) ?? 0;
    final totalCost = int.tryParse(_safeParseNumStr(fin['total_system_cost'], '0')) ?? 0;
    final pmSubsidy = int.tryParse(_safeParseNumStr(fin['pm_surya_ghar_subsidy'], '0')) ?? 0;
    final monthlySavings = int.tryParse(_safeParseNumStr(fin['monthly_savings_inr'], '0')) ?? 0;
    final paybackYears = double.tryParse(_safeParseNumStr(fin['payback_years'], '0')) ?? 0.0;
    final savings25 = int.tryParse(_safeParseNumStr(fin['25_year_savings'], '0')) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net Investment Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Column(children: [
              const Text("Net Investment", style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Text("₹${_formatNum(netInvestment)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const Text("After all subsidies", style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          // Payback Progress Bar
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Payback Period", style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("${paybackYears.toStringAsFixed(1)} years", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: paybackYears > 0 ? (1 - paybackYears / 15).clamp(0, 1) : 0,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(paybackYears < 5 ? Colors.greenAccent : paybackYears < 8 ? Colors.amber : Colors.redAccent),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(paybackYears < 5 ? "⚡ Excellent" : paybackYears < 8 ? "Good" : "Long payback", style: TextStyle(color: paybackYears < 5 ? Colors.greenAccent : Colors.amber, fontSize: 10)),
                const Text("15 yr max", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ]),
            ]),
          ).animate().fadeIn(delay: 200.ms),

          // Cost Breakdown
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _solarSpecCard("₹${_formatNum(totalCost)}", "System Cost", Icons.paid, Colors.amber)),
            const SizedBox(width: 10),
            Expanded(child: _solarSpecCard("₹${_formatNum(pmSubsidy)}", "PM Subsidy", Icons.receipt, Colors.greenAccent)),
          ]).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _solarSpecCard("₹${_formatNum(monthlySavings)}", "Monthly Save", Icons.savings, Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _solarSpecCard("₹${_formatNum(savings25)}", "25yr Savings", Icons.trending_up, Colors.purpleAccent)),
          ]).animate().fadeIn(delay: 400.ms),

          // CTA
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubsidyScreen())),
              icon: const Icon(Icons.bolt),
              label: const Text("CLAIM SUBSIDIES NOW", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _buildSolarInstallationTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final install = Map<String, dynamic>.from(data['installation_considerations'] as Map? ?? {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow("Roof Access", "${install['roof_access']}"),
          _infoRow("Waterproofing", install['waterproofing_needed'] == true ? "Required" : "Not Required"),
          _infoRow("Complexity", "${install['installation_complexity']}"),
          const SizedBox(height: 20),
          const Text("Professional Recommendation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(data['recommendation'] ?? "No recommendation available.", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildGreenArchitectureTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final spatial = data['spatial_optimization'] as List? ?? [];
    final greenArch = data['green_architecture'] != null ? Map<String, dynamic>.from(data['green_architecture'] as Map) : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Spatial Optimization", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          if (spatial.isEmpty && greenArch == null)
             const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No layout optimizations found.", style: TextStyle(color: Colors.white54)))),
             
          ...spatial.map((opt) {
             return Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.blueAccent.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [
                     const Icon(Icons.architecture, color: Colors.blueAccent, size: 20),
                     const SizedBox(width: 8),
                     Expanded(child: Text("${opt['appliance']} Organization", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                   ]),
                   const SizedBox(height: 12),
                   _infoRowSmall("Current Location", opt['current_location']?.toString() ?? 'Unknown'),
                   const SizedBox(height: 6),
                   _infoRowSmall("Issue", opt['issue']?.toString() ?? 'None', isError: true),
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                       Row(children: const [Icon(Icons.lightbulb, color: Colors.greenAccent, size: 14), SizedBox(width: 6), Text("Recommendation", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold))]),
                       const SizedBox(height: 6),
                       Text(opt['recommendation']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                       if (opt['savings_potential'] != null) ...[
                         const SizedBox(height: 6),
                         Text("Potential Savings: ₹${opt['savings_potential']}/yr", style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                       ]
                     ]),
                   )
                 ],
               ),
             );
          }),

          if (greenArch != null) ...[
            const SizedBox(height: 8),
            const Text("Green Layout Additions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (greenArch['layout_advice'] != null)
              _adviceCard(Icons.space_dashboard, "Layout Advice", greenArch['layout_advice'], Colors.cyan),
            const SizedBox(height: 12),
            if (greenArch['sustainable_additions'] != null)
              _adviceCard(Icons.eco, "Sustainable Additions", greenArch['sustainable_additions'], Colors.green),
          ]
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

  void _showEcoStoryDialog(BuildContext context, dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final score = Map<String, dynamic>.from(data['sustainability_score'] as Map? ?? {});
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
                    _minimalFeature(context, "Passport", Icons.assignment_ind, const Color(0xFFFFC6FF), const ImpactPassportScreen()),
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
  Widget _buildDynamicImpactCard(dynamic carbonData) {
    final carbon = Map<String, dynamic>.from(carbonData as Map? ?? {});
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
  Widget _buildCostOfInactionCard(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final eco = Map<String, dynamic>.from(data['economics'] as Map? ?? {});
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

  // ==========================================
  // PRODUCT SCAN WIDGETS
  // ==========================================

  Widget _buildProductLifecycleTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final lifecycle = Map<String, dynamic>.from(data['carbon_lifecycle'] as Map? ?? {});

    if (lifecycle.isEmpty) return const Center(child: Text("No Lifecycle Data", style: TextStyle(color: Colors.white)));

    final num totalCo2 = lifecycle['total_grams_co2'] ?? 0;
    final Map<String, dynamic> breakdown = Map<String, dynamic>.from(lifecycle['breakdown'] as Map? ?? {});
    
    // Calculate percentages for the stacked bar
    double rawMat = (breakdown['raw_material_extraction'] ?? 0) / (totalCo2 == 0 ? 1 : totalCo2);
    double mfg = (breakdown['manufacturing'] ?? 0) / (totalCo2 == 0 ? 1 : totalCo2);
    double transport = (breakdown['transportation'] ?? 0) / (totalCo2 == 0 ? 1 : totalCo2);
    double pack = (breakdown['packaging'] ?? 0) / (totalCo2 == 0 ? 1 : totalCo2);
    double usePhase = (breakdown['use_phase'] ?? 0) / (totalCo2 == 0 ? 1 : totalCo2);
    double eol = (breakdown['end_of_life'] ?? 0) / (totalCo2 == 0 ? 1 : totalCo2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.2), Colors.cyan.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.withOpacity(0.3))
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud, color: Colors.purpleAccent, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Total CO₂ Footprint", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text("${totalCo2}g", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      if (lifecycle['comparison'] != null)
                        Text(lifecycle['comparison'], style: const TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("Lifecycle Breakdown", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          
          // Animated Stacked Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
               height: 24,
               width: double.infinity,
               color: Colors.white10,
               child: Row(
                 children: [
                   if (rawMat > 0) Expanded(flex: (rawMat * 100).toInt(), child: Tooltip(message: "Raw Material: ${(rawMat*100).toInt()}%", child: Container(color: Colors.redAccent))),
                   if (mfg > 0) Expanded(flex: (mfg * 100).toInt(), child: Tooltip(message: "Manufacturing: ${(mfg*100).toInt()}%", child: Container(color: Colors.orangeAccent))),
                   if (transport > 0) Expanded(flex: (transport * 100).toInt(), child: Tooltip(message: "Transport: ${(transport*100).toInt()}%", child: Container(color: Colors.amber))),
                   if (pack > 0) Expanded(flex: (pack * 100).toInt(), child: Tooltip(message: "Packaging: ${(pack*100).toInt()}%", child: Container(color: Colors.yellow))),
                   if (usePhase > 0) Expanded(flex: (usePhase * 100).toInt(), child: Tooltip(message: "Use Phase: ${(usePhase*100).toInt()}%", child: Container(color: Colors.blueAccent))),
                   if (eol > 0) Expanded(flex: (eol * 100).toInt(), child: Tooltip(message: "End of Life: ${(eol*100).toInt()}%", child: Container(color: Colors.grey))),
                 ],
               ),
            ),
          ).animate().slideX(duration: 600.ms, begin: -1, end: 0),
          
          const SizedBox(height: 16),
          _legendItem(Colors.redAccent, "Raw Material", "${breakdown['raw_material_extraction'] ?? 0}g"),
          _legendItem(Colors.orangeAccent, "Manufacturing", "${breakdown['manufacturing'] ?? 0}g"),
          _legendItem(Colors.amber, "Transport", "${breakdown['transportation'] ?? 0}g"),
          _legendItem(Colors.yellow, "Packaging", "${breakdown['packaging'] ?? 0}g"),
          _legendItem(Colors.blueAccent, "Use Phase", "${breakdown['use_phase'] ?? 0}g"),
          _legendItem(Colors.grey, "End of Life", "${breakdown['end_of_life'] ?? 0}g"),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.greenAccent.withOpacity(0.3))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [Icon(Icons.recycling, color: Colors.greenAccent, size: 20), SizedBox(width: 8), Text("End of Life Impact", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                if (lifecycle['if_recycled_co2_saved'] != null)
                  _infoRowSmall("If Recycled", "Saves ${lifecycle['if_recycled_co2_saved']}g CO₂", isPos: true),
                const SizedBox(height: 8),
                if (lifecycle['if_landfilled_impact'] != null)
                  _infoRowSmall("If Landfilled", lifecycle['if_landfilled_impact'], isError: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMaterialTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final material = Map<String, dynamic>.from(data['material_intelligence'] as Map? ?? {});
    final circular = Map<String, dynamic>.from(data['circular_economy'] as Map? ?? {});
    
    final int recycleScore = material['recyclability_score'] ?? 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3))
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Primary Material", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(material['primary_material'] ?? 'Unknown', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                        if (material['material_code'] != null)
                          Text("Code: ${material['material_code']}", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60, height: 60,
                          child: CircularProgressIndicator(
                            value: recycleScore / 100, 
                            strokeWidth: 6, 
                            backgroundColor: Colors.white12, 
                            valueColor: AlwaysStoppedAnimation(recycleScore > 70 ? Colors.green : (recycleScore > 30 ? Colors.orange : Colors.red))
                          ),
                        ),
                        Text("$recycleScore%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                if (material['current_recycling_rate_india'] != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Actual recycling rate in India is approx. ${material['current_recycling_rate_india']}", style: const TextStyle(color: Colors.white70, fontSize: 11))),
                    ]),
                  )
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(child: _miniStatCard(Icons.science, "Toxicity", material['toxicity_level'] ?? 'Unknown', material['toxicity_level'] == 'Safe' ? Colors.green : Colors.red)),
              const SizedBox(width: 12),
              Expanded(child: _miniStatCard(Icons.water, "Microplastic", material['microplastic_risk'] ?? 'Unknown', material['microplastic_risk'] == 'Low' ? Colors.green : Colors.red)),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text("Circular Economy Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _infoRowSmall("Repairable", circular['repairable'] == true ? "Yes" : "No", isPos: circular['repairable'] == true),
                const SizedBox(height: 12),
                _infoRowSmall("Biodegradable", material['biodegradable'] == true ? "Yes (${material['decomposition_time_years']} yrs)" : "No (${material['decomposition_time_years'] ?? '?'} yrs)", isPos: material['biodegradable'] == true, isError: material['biodegradable'] == false),
                const SizedBox(height: 12),
                _infoRowSmall("Est. Trade-in", "₹${circular['trade_in_value_inr'] ?? 0}"),
                if (circular['proper_disposal'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.delete_outline, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Disposal: ${circular['proper_disposal']}", style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ])
                ]
              ],
            ),
          ),
          
          if (circular['upcycling_ideas'] != null && (circular['upcycling_ideas'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.tealAccent.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.lightbulb, color: Colors.tealAccent, size: 18), SizedBox(width: 8), Text("Upcycling Idea", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 8),
                    Text((circular['upcycling_ideas'] as List).firstOrNull ?? "None", style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                ]),
              ),
            )
        ],
      ),
    );
  }

  Widget _miniStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
  
  Widget _infoRowSmall(String label, String value, {bool isError = false, bool isPos = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: isError ? Colors.redAccent : (isPos ? Colors.greenAccent : Colors.white), fontSize: 12, fontWeight: isPos || isError ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }

  Widget _buildAlternativesTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final alts = data['green_alternatives'] as List? ?? [];
    final nudge = data['behavioral_nudge'] != null ? Map<String, dynamic>.from(data['behavioral_nudge'] as Map) : null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           if (nudge != null) ...[
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 gradient: LinearGradient(colors: [Colors.green.withOpacity(0.2), Colors.teal.withOpacity(0.1)]),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [
                     const Icon(Icons.people, color: Colors.greenAccent, size: 20),
                     const SizedBox(width: 8),
                     Expanded(child: Text(nudge['social_proof'] ?? "Join the movement", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14))),
                   ]),
                   const SizedBox(height: 12),
                   Text(nudge['message'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                   if (nudge['urgency'] != null) ...[
                     const SizedBox(height: 8),
                     Text(nudge['urgency'], style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontStyle: FontStyle.italic)),
                   ],
                   if (nudge['gamification'] != null) ...[
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                           const SizedBox(width: 6),
                           Text(nudge['gamification'], style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     )
                   ]
                 ],
               ),
             ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
             const SizedBox(height: 24),
           ],
           
           const Text("Top Green Alternatives", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           
           if (alts.isEmpty) const Text("No alternatives found.", style: TextStyle(color: Colors.white54)),
           ...alts.map((alt) => Container(
             margin: const EdgeInsets.only(bottom: 16),
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Expanded(
                     child: Text(alt['product'] ?? "Alternative", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                   ),
                   if (alt['rating'] != null)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                       child: Row(children: [
                         const Icon(Icons.star, color: Colors.amber, size: 12),
                         const SizedBox(width: 4),
                         Text("${alt['rating']}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                       ]),
                     )
                 ],
               ),
               const SizedBox(height: 4),
               Text("Brand: ${alt['brand']}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
               
               const SizedBox(height: 16),
               Row(children: [
                 Expanded(child: _miniAltStat(Icons.payments, "Cost", "₹${alt['upfront_cost_inr'] ?? 0}")),
                 const SizedBox(width: 8),
                 Expanded(child: _miniAltStat(Icons.eco, "CO₂ Saved", "${alt['annual_savings_co2_kg'] ?? 0}kg/yr", color: Colors.greenAccent)),
                 if (alt['annual_savings_money_inr'] != null) ...[
                   const SizedBox(width: 8),
                   Expanded(child: _miniAltStat(Icons.savings, "Savings", "₹${alt['annual_savings_money_inr']}/yr", color: Colors.greenAccent)),
                 ]
               ]),
               
               if (alt['break_even_uses'] != null) ...[
                 const SizedBox(height: 16),
                 Container(
                   width: double.infinity,
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                   child: Text("♻️ Pays for itself environmentally after ${alt['break_even_uses']} uses", style: const TextStyle(color: Colors.cyanAccent, fontSize: 11), textAlign: TextAlign.center),
                 ),
               ],
               
               const SizedBox(height: 16),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () {},
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: Colors.black,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Text("Find on "),
                       Text(alt['availability'] ?? "Store", style: const TextStyle(fontWeight: FontWeight.bold)),
                       const SizedBox(width: 6),
                       const Icon(Icons.open_in_new, size: 14)
                     ],
                   ),
                 ),
               )
             ]),
           ))
        ],
      ),
    );
  }
  
  Widget _miniAltStat(IconData icon, String label, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: Colors.white38, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // ==========================================
  // BILL OCR WIDGETS
  // ==========================================

  Widget _buildBillDetailsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final extracted = Map<String, dynamic>.from(data['extracted_data'] as Map? ?? {});
    final totalAmount = (extracted['total_amount_inr'] as num?)?.toInt() ?? 0;
    final units = (extracted['units_consumed'] as num?)?.toInt() ?? 0;
    final rate = extracted['rate_per_unit'] ?? '—';
    final provider = extracted['provider'] ?? 'Unknown';
    final period = extracted['billing_period'] ?? 'Current Month';
    final billType = extracted['bill_type'] ?? 'electricity';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.15), Colors.orange.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(billType == 'water' ? Icons.water_drop : billType == 'gas' ? Icons.local_fire_department : Icons.bolt, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Text(provider, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
              const SizedBox(height: 16),
              Text("₹$totalAmount", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
              Text(period, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          // Usage Gauge
          const SizedBox(height: 24),
          const Text("Usage Summary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _billMetric(Icons.flash_on, "$units", "Units", Colors.amber),
                _billMetric(Icons.attach_money, "₹$rate", "Per Unit", Colors.greenAccent),
                _billMetric(Icons.calendar_today, period.split(' ').first, "Month", Colors.blueAccent),
              ]),
              const SizedBox(height: 16),
              // Usage bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (units / 500).clamp(0, 1),
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation(units > 300 ? Colors.redAccent : units > 150 ? Colors.amber : Colors.greenAccent),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("0 units", style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text(units > 300 ? "⚠ High Usage" : units > 150 ? "Moderate" : "✓ Efficient", style: TextStyle(color: units > 300 ? Colors.redAccent : units > 150 ? Colors.amber : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                const Text("500 units", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ]),
            ]),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _billMetric(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }

  Widget _buildBillAnalysisTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final analysis = Map<String, dynamic>.from(data['analysis'] as Map? ?? {});
    final tariffs = data['tariff_breakdown'] as List? ?? [];
    final highUsage = analysis['high_usage_flag'] == true;
    final maxSlabCost = tariffs.isNotEmpty
        ? tariffs.map((t) => (t['cost'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b)
        : 1000.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Usage Alert Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                highUsage ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                highUsage ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: highUsage ? Colors.redAccent.withOpacity(0.4) : Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (highUsage ? Colors.redAccent : Colors.greenAccent).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(highUsage ? Icons.warning_rounded : Icons.check_circle, color: highUsage ? Colors.redAccent : Colors.greenAccent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(highUsage ? "Above Average Usage" : "Below Average Usage", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(analysis['vs_average'] ?? "Usage Analysis", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              )),
            ]),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

          // Tariff Slab Breakdown
          const SizedBox(height: 24),
          const Text("Tariff Slab Breakdown", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          ...tariffs.asMap().entries.map((entry) {
            final t = entry.value;
            final idx = entry.key;
            final cost = (t['cost'] as num?)?.toDouble() ?? 0;
            final units = t['units'] ?? 0;
            final isCurrentSlab = analysis['slab_position'] != null && analysis['slab_position'].toString().contains(t['slab']?.toString().split(' ').first ?? '___');
            final barColors = [Colors.greenAccent, Colors.cyan, Colors.amber, Colors.orange, Colors.redAccent];
            final color = barColors[idx.clamp(0, barColors.length - 1)];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isCurrentSlab ? 0.08 : 0.03),
                borderRadius: BorderRadius.circular(12),
                border: isCurrentSlab ? Border.all(color: Colors.amber, width: 1.5) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      if (isCurrentSlab) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: const Text("YOU", style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      Text(t['slab'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                    Text("₹${cost.toInt()}", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: maxSlabCost > 0 ? cost / maxSlabCost : 0,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (150 + idx * 100).ms).slideX(begin: 0.05, end: 0);
          }),
        ],
      ),
    );
  }
  
  Widget _buildBillSavingsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final strategies = data['reduction_strategies'] as List? ?? [];
    final totalSavings = strategies.fold<double>(0, (sum, s) => sum + ((s['monthly_savings_inr'] as num?)?.toDouble() ?? 0));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Savings Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Column(children: [
              const Icon(Icons.savings, color: Colors.greenAccent, size: 32),
              const SizedBox(height: 10),
              const Text("Total Potential Savings", style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 6),
              Text("₹${totalSavings.toInt()}/mo", style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
              Text("₹${(totalSavings * 12).toInt()}/year", style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 24),
          Text("${strategies.length} Saving Strategies", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),

          ...strategies.asMap().entries.map((entry) {
            final s = entry.value;
            final idx = entry.key;
            final monthlySavings = (s['monthly_savings_inr'] as num?)?.toInt() ?? 0;
            final unitsSaved = (s['units_saved'] as num?)?.toInt() ?? 0;
            final implCost = (s['implementation_cost'] as num?)?.toInt() ?? 0;
            final paybackMonths = monthlySavings > 0 ? (implCost / monthlySavings).ceil() : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text("${idx + 1}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s['strategy'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _savingsBadge(Icons.flash_on, "$unitsSaved units", Colors.amber),
                    const SizedBox(width: 8),
                    _savingsBadge(Icons.savings, "₹$monthlySavings/mo", Colors.greenAccent),
                    if (implCost > 0) ...[
                      const SizedBox(width: 8),
                      _savingsBadge(Icons.build, "₹$implCost cost", Colors.blueAccent),
                    ],
                  ]),
                  if (implCost > 0 && paybackMonths > 0) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.replay, color: Colors.white38, size: 14),
                      const SizedBox(width: 6),
                      Text("ROI in $paybackMonths month${paybackMonths != 1 ? 's' : ''}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ]),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: (200 + idx * 120).ms).slideY(begin: 0.05, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _savingsBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  // ==========================================
  // FOOD AUDIT WIDGETS
  // ==========================================
  
  Widget _buildFoodImpactTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final carbon = Map<String, dynamic>.from(data['carbon_footprint'] as Map? ?? {});
    final totalCo2 = (carbon['total_kg_co2'] as num?)?.toDouble() ?? 0;
    final breakdown = carbon['breakdown'] as List? ?? [];
    final comparison = carbon['comparison_text'] ?? '';
    final maxPct = breakdown.isNotEmpty
        ? breakdown.map((b) => (b['percentage'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b)
        : 100.0;
    final List<Color> barColors = [Colors.redAccent, Colors.orangeAccent, Colors.amber, Colors.teal, Colors.cyan, Colors.indigo];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero CO₂ Gauge
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.15), Colors.red.withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.orange.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120, height: 120,
                        child: CircularProgressIndicator(
                          value: (totalCo2 / 10).clamp(0, 1),
                          strokeWidth: 10,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(totalCo2 > 5 ? Colors.redAccent : totalCo2 > 2 ? Colors.orange : Colors.greenAccent),
                        ),
                      ).animate().rotate(duration: 1500.ms, begin: -0.05, end: 0),
                      Column(
                        children: [
                          Text("${totalCo2.toStringAsFixed(1)}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          const Text("kg CO₂", style: TextStyle(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ],
                  ).animate().scale(duration: 600.ms, begin: const Offset(0.8, 0.8), end: const Offset(1, 1), curve: Curves.elasticOut),
                  const SizedBox(height: 16),
                  Text(data['product_name'] ?? 'Meal', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          // Equivalence callout
          if (comparison.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(comparison, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],

          // Ingredient Breakdown
          const SizedBox(height: 24),
          const Text("Ingredient Breakdown", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          ...breakdown.asMap().entries.map((entry) {
            final b = entry.value;
            final idx = entry.key;
            final pct = (b['percentage'] as num?)?.toDouble() ?? 0;
            final co2 = (b['kg_co2'] as num?)?.toDouble();
            final color = barColors[idx % barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b['ingredient'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                      Row(children: [
                        if (co2 != null) Text("${co2.toStringAsFixed(1)} kg  ", style: TextStyle(color: color, fontSize: 12)),
                        Text("${pct.toInt()}%", style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxPct > 0 ? pct / maxPct : 0,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (200 + idx * 100).ms).slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildFoodSwapsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final swaps = data['greener_swaps'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.eco, color: Colors.greenAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Greener Alternatives", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${swaps.length} swap${swaps.length != 1 ? 's' : ''} found", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          if (swaps.isEmpty) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 56),
                const SizedBox(height: 12),
                const Text("Already Eco-Friendly!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                const Text("This meal is already a great choice.", style: TextStyle(color: Colors.white54)),
              ]),
            ).animate().scale(duration: 500.ms, begin: const Offset(0.8, 0.8)),
          ],

          const SizedBox(height: 16),
          ...swaps.asMap().entries.map((entry) {
            final s = entry.value;
            final idx = entry.key;
            final reduction = (s['carbon_reduction_percent'] as num?)?.toInt() ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // From
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(s['swap_from'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            const Icon(Icons.arrow_forward, color: Colors.greenAccent, size: 22),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text("-$reduction%", style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      // To
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.check, color: Colors.greenAccent, size: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(s['swap_to'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Reduction bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: reduction / 100,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("$reduction% less carbon impact", style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                ],
              ),
            ).animate().fadeIn(delay: (200 + idx * 120).ms).slideY(begin: 0.08, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildFoodMilesTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final miles = Map<String, dynamic>.from(data['food_miles'] as Map? ?? {});
    final estimatedKm = (miles['estimated_km'] as num?)?.toInt() ?? 0;
    final localPct = (miles['local_percentage'] as num?)?.toInt() ?? 0;
    final importedItems = miles['imported_items'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distance Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.15), Colors.indigo.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.local_shipping, color: Colors.blueAccent, size: 36),
                const SizedBox(height: 12),
                Text("$estimatedKm", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                const Text("kilometers traveled", style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: estimatedKm < 100 ? Colors.greenAccent.withOpacity(0.2) : estimatedKm < 500 ? Colors.amber.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estimatedKm < 100 ? "🌿 Low Food Miles" : estimatedKm < 500 ? "⚠️ Moderate" : "🔴 High Food Miles",
                    style: TextStyle(color: estimatedKm < 100 ? Colors.greenAccent : estimatedKm < 500 ? Colors.amber : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          // Local vs Imported
          const SizedBox(height: 24),
          const Text("Local vs Imported", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text("Local $localPct%", style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                    Row(children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text("Imported ${100 - localPct}%", style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: Row(children: [
                      Expanded(flex: localPct.clamp(1, 100), child: Container(color: Colors.greenAccent)),
                      Expanded(flex: (100 - localPct).clamp(1, 100), child: Container(color: Colors.orangeAccent)),
                    ]),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          // Imported Items
          if (importedItems.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text("Imported Items", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: importedItems.asMap().entries.map((entry) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.flight, size: 14, color: Colors.orangeAccent),
                  const SizedBox(width: 6),
                  Text(entry.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ).animate().fadeIn(delay: (300 + entry.key * 80).ms).slideX(begin: 0.1, end: 0)).toList(),
            ),
          ],

          // Buy Local Tip
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.1), Colors.teal.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.greenAccent, size: 22),
                const SizedBox(width: 12),
                const Expanded(child: Text("Buying from local farmers markets can reduce food miles by up to 90% and supports your community.", style: TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  // ==========================================
  // VEHICLE CHECK WIDGETS
  // ==========================================

  Widget _buildVehicleEmissionsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final emissions = Map<String, dynamic>.from(data['emissions'] as Map? ?? {});
    final vehicle = Map<String, dynamic>.from(data['vehicle_analysis'] as Map? ?? {});
    final annualCo2 = (emissions['annual_kg_co2'] as num?)?.toDouble() ?? 0;
    final comparison = emissions['comparison_text'] ?? '';
    final basedOnKm = emissions['based_on_km_year'] ?? 15000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CO₂ Gauge Hero
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.red.withOpacity(0.12), Colors.orange.withOpacity(0.06)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 130, height: 130,
                        child: CircularProgressIndicator(
                          value: (annualCo2 / 5000).clamp(0, 1),
                          strokeWidth: 12,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(annualCo2 > 3000 ? Colors.redAccent : annualCo2 > 1500 ? Colors.orange : Colors.greenAccent),
                        ),
                      ).animate().rotate(duration: 1500.ms, begin: -0.05, end: 0),
                      Column(children: [
                        Text("${annualCo2.toInt()}", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                        const Text("kg CO₂/yr", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                    ],
                  ).animate().scale(duration: 600.ms, begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  Text("Based on $basedOnKm km/year", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          // Comparison callout
          if (comparison.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
              child: Row(children: [
                const Icon(Icons.park, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(comparison, style: const TextStyle(color: Colors.white70, fontSize: 13))),
              ]),
            ).animate().fadeIn(delay: 200.ms),
          ],

          // Vehicle Profile
          const SizedBox(height: 24),
          const Text("Vehicle Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.directions_car, color: Colors.blueAccent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle['estimated_model'] ?? data['product_name'] ?? 'Vehicle', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${vehicle['type'] ?? 'Car'} · ${vehicle['fuel_type'] ?? 'Petrol'}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                )),
              ]),
              const SizedBox(height: 14),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _vehicleStat("Mileage", "${vehicle['estimated_mileage_kmpl'] ?? '—'} kmpl", Icons.speed),
                _vehicleStat("Fuel", vehicle['fuel_type'] ?? '—', Icons.local_gas_station),
                _vehicleStat("CO₂/km", "${annualCo2 > 0 && basedOnKm > 0 ? (annualCo2 * 1000 / basedOnKm).toInt() : '—'} g", Icons.co2),
              ]),
            ]),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Widget _vehicleStat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white38, size: 18),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }

  Widget _buildEVSwitchTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final ev = Map<String, dynamic>.from(data['ev_comparison'] as Map? ?? {});
    final emissions = Map<String, dynamic>.from(data['emissions'] as Map? ?? {});
    final annualSavings = (ev['annual_fuel_savings'] as num?)?.toInt() ?? 0;
    final co2Reduction = (ev['annual_co2_reduction_percent'] as num?)?.toInt() ?? 0;
    final fameSubsidy = (ev['fame_subsidy'] as num?)?.toInt() ?? 0;
    final stateSubsidy = (ev['state_subsidy'] as num?)?.toInt() ?? 0;
    final breakeven = (ev['breakeven_years'] as num?)?.toDouble() ?? 0;
    final evPrice = (ev['ev_price_inr'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended EV Showcase
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text("⚡ RECOMMENDED EV", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 14),
                const Icon(Icons.electric_car, color: Colors.greenAccent, size: 40),
                const SizedBox(height: 10),
                Text(ev['recommended_ev'] ?? 'Electric Alternative', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (evPrice > 0) ...[
                  const SizedBox(height: 6),
                  Text("₹${_formatLakh(evPrice)}", style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
                const SizedBox(height: 18),
                // Savings row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _evMetric("Save/Year", "₹${_formatLakh(annualSavings)}", Colors.greenAccent),
                    _evMetric("CO₂ Cut", "$co2Reduction%", Colors.cyanAccent),
                    _evMetric("Breakeven", "${breakeven.toStringAsFixed(1)} yr", Colors.amber),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          // Subsidies
          const SizedBox(height: 20),
          const Text("Available Subsidies", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _subsidyCard("FAME II", "₹${_formatLakh(fameSubsidy)}", Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _subsidyCard("State", "₹${_formatLakh(stateSubsidy)}", Colors.purple)),
          ]).animate().fadeIn(delay: 200.ms),

          // Net cost
          if (evPrice > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Net Cost After Subsidies", style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text("₹${_formatLakh(evPrice - fameSubsidy - stateSubsidy)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ).animate().fadeIn(delay: 300.ms),
          ],

          // Breakeven Timeline
          const SizedBox(height: 20),
          const Text("Breakeven Timeline", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Year 0", style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                Text("Year ${breakeven.toStringAsFixed(0)}", style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                const Text("Year 10", style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (breakeven / 10).clamp(0, 1),
                  backgroundColor: Colors.greenAccent.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("← Investment", style: TextStyle(color: Colors.redAccent, fontSize: 10)),
                const Text("Profit →", style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
              ]),
            ]),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _evMetric(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]);
  }

  Widget _subsidyCard(String name, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
    );
  }

  String _formatLakh(int value) {
    if (value >= 100000) return "${(value / 100000).toStringAsFixed(1)}L";
    if (value >= 1000) return "${(value / 1000).toStringAsFixed(0)}K";
    return value.toString();
  }
  
  Widget _buildVehicleSavingsTab(dynamic inputData) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(inputData as Map? ?? {});
    final ev = Map<String, dynamic>.from(data['ev_comparison'] as Map? ?? {});
    final emissions = Map<String, dynamic>.from(data['emissions'] as Map? ?? {});
    final annualFuelSavings = (ev['annual_fuel_savings'] as num?)?.toDouble() ?? 0;
    final annualCo2 = (emissions['annual_kg_co2'] as num?)?.toDouble() ?? 0;
    final co2ReductionPct = (ev['annual_co2_reduction_percent'] as num?)?.toDouble() ?? 70;
    final annualCo2Saved = annualCo2 * co2ReductionPct / 100;
    final treesEquivalent = (annualCo2Saved / 21).round(); // ~21kg CO₂ per tree/year

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lifetime Savings Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.withOpacity(0.15), Colors.teal.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Column(children: [
              const Icon(Icons.savings, color: Colors.greenAccent, size: 36),
              const SizedBox(height: 12),
              const Text("Projected Savings", style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 8),
              Text("₹${_formatLakh((annualFuelSavings * 10).toInt())}", style: const TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.bold)),
              const Text("over 10 years", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),

          // Savings Timeline
          const SizedBox(height: 24),
          const Text("Cumulative Savings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 14),
          ...[3, 5, 10, 15].map((years) {
            final savings = (annualFuelSavings * years).toInt();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                SizedBox(width: 50, child: Text("$years yr", style: const TextStyle(color: Colors.white54, fontSize: 13))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (years / 15).clamp(0, 1),
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation(Colors.greenAccent.withOpacity(0.7)),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text("₹${_formatLakh(savings)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            );
          }),

          // Environmental Impact
          const SizedBox(height: 20),
          const Text("Environmental Impact", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _envImpactCard(Icons.co2, "${annualCo2Saved.toInt()} kg", "CO₂ saved/yr", Colors.cyan)),
            const SizedBox(width: 10),
            Expanded(child: _envImpactCard(Icons.park, "$treesEquivalent", "trees equivalent", Colors.greenAccent)),
          ]).animate().fadeIn(delay: 300.ms),

          // Maintenance savings tip
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.withOpacity(0.1), Colors.indigo.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.build_circle, color: Colors.blueAccent, size: 22),
              const SizedBox(width: 12),
              const Expanded(child: Text("EVs have 60% lower maintenance costs — no oil changes, fewer brake repairs, and simpler drivetrains.", style: TextStyle(color: Colors.white70, fontSize: 12))),
            ]),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Widget _envImpactCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
    );
  }

}

