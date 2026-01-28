import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/leaf_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert'; // For Base64 decoding
import 'dart:typed_data';
import '../widgets/scanner_loading.dart';
import 'chat_screen.dart';
import 'leaderboard_screen.dart';
import 'community_screen.dart';
import 'subsidy_screen.dart';
import 'maintenance_screen.dart';
import 'carbon_screen.dart';
import '../widgets/questionnaire_dialog.dart';
import 'top_picks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService();
  bool _isAnalyzing = false;
  Uint8List? _currentImageBytes;
  Map<String, dynamic> _lastAnalysisData = {};

  Future<void> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      if (mounted) {
         setState(() {
           _isAnalyzing = true; // Show loading for Step 1
           _currentImageBytes = bytes;
         });
      }

      try {
        // Step 1: Get Context Questions (AI)
        final contextResult = await apiService.getAnalysisQuestions(bytes, image.name);
        
        if (mounted) {
           setState(() => _isAnalyzing = false); // Stop loading to show dialog
           
           final questions = contextResult['questions'] as List? ?? [];
           
           // Show Dynamic Dialog
           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (ctx) => QuestionnaireDialog(
               questions: questions,
               onSubmit: (answers) async {
                  // Step 2: Full Analysis with Answers
                  if (mounted) setState(() => _isAnalyzing = true);
                  
                  try {
                    final result = await apiService.uploadImage(bytes, image.name, answers);
                    if (mounted) {
                       setState(() {
                         _isAnalyzing = false;
                         _lastAnalysisData = result;
                       });
                       _showResults(result, bytes, "User Custom");
                    }
                  } catch (e) {
                    if (mounted) setState(() => _isAnalyzing = false);
                  }
               },
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
          height: 600,
          child: Column(
            children: [
              // Header Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                ),
              ),
              
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
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
                              Tab(text: "Materials"),
                              Tab(text: "Alternatives"),
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
                                _buildMaterialsTab(data),
                                _buildAlternativesTab(data),
                              ],
                        ),
                      ),
                    ],
                  ),
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
    final breakdown = carbon['breakdown'] ?? {};
    final score = data['sustainability_score'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Expanded(child: Text(data['product_name'] ?? 'Unknown Product', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    if ((data['data_source'] ?? '').contains('Verified'))
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                      )
                  ],
                ),
                Text(data['data_source'] ?? 'AI Estimate', style: TextStyle(color: (data['data_source'] ?? '').contains('Verified') ? Colors.blueAccent : Colors.grey, fontSize: 12)),
              ]),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _getScoreColor(score['grade']), shape: BoxShape.circle),
                child: Text(score['grade'] ?? '?', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
              )
            ],
          ),
          const SizedBox(height: 24),
          _infoCard(Icons.co2, "Carbon Footprint", "${carbon['total_kg_co2'] ?? '?'} kg CO2e", carbon['comparison_text'] ?? ''),
          const SizedBox(height: 16),
          const Text("Lifecycle Breakdown:", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _breakdownRow("Manufacturing", breakdown['manufacturing']),
          _breakdownRow("Transport", breakdown['transport']),
          _breakdownRow("Use Phase", breakdown['use_phase']),
          _breakdownRow("End of Life", breakdown['end_of_life']),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab(Map<String, dynamic> data) {
    final materials = data['material_breakdown'] as List? ?? [];
    final recovery = data['recovery_info'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Text("Material Composition", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           ...materials.map((m) => Container(
             margin: const EdgeInsets.only(bottom: 8),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m['component'] ?? '', style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                      Text(m['material'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text(m['recyclability'] ?? '', style: const TextStyle(color: Colors.greenAccent))
                ],
              ),
           )),
           const SizedBox(height: 24),
           const Divider(color: Colors.grey),
           const SizedBox(height: 16),
           const Text("Recovery Info", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           _infoRow("Time to Recycle", recovery['recycling_time']),
           _infoRow("Scrap Value", "₹${recovery['recovery_value_inr']}"),
           const SizedBox(height: 16),
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
             child: Row(children: [
               const Icon(Icons.recycling, color: Colors.green),
               const SizedBox(width: 12),
               Expanded(child: Text(recovery['recycling_action'] ?? 'Recycle locally', style: const TextStyle(color: Colors.greenAccent)))
             ]),
           )
         ],
      ),
    );
  }

  Widget _buildRoomOverviewTab(Map<String, dynamic> data) {
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
                 child: Text("${data['efficiency_score'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
               )
            ],
          ),
          const SizedBox(height: 24),
          _infoCard(Icons.home, "Room Rating", "${data['efficiency_score']}/100", "Based on appliances & layout"),
          const SizedBox(height: 20),
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.orange.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.orange.withOpacity(0.3)),
             ),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.lightbulb, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Recommendation:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange))]),
                  const SizedBox(height: 4),
                  Text(data['recommendation'] ?? '', style: const TextStyle(color: Colors.white70)),
                ]
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAppliancesTab(Map<String, dynamic> data) {
    final appliances = data['appliances'] as List? ?? [];
    if (appliances.isEmpty) {
      return const Center(child: Text("No high-energy appliances detected.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appliances.length,
      itemBuilder: (ctx, i) {
        final a = appliances[i];
        return Card(
           margin: const EdgeInsets.only(bottom: 12),
           color: Colors.white10,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           child: Padding(
             padding: const EdgeInsets.all(12),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                   Text(a['type'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   Text(a['efficiency_rating'] ?? '', style: const TextStyle(color: Colors.greenAccent))
                 ]),
                 const Divider(color: Colors.white24),
                 Text("Power: ${a['current_power_consumption']}", style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 8),
                 Text("Replace with: ${a['recommended_replacement']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                 Text("Est. Savings: ${a['financial_savings_year']}/yr", style: const TextStyle(color: Colors.green)),
               ],
             ),
           ),
        );
      },
    );
  }

  Widget _buildGreenArchitectureTab(Map<String, dynamic> data) {
    final arch = data['green_architecture'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            const Text("Layout & Design", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
               child: Text(arch['layout_advice'] ?? 'No advice', style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 24),
            const Text("Sustainable Additions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
               child: Text(arch['sustainable_additions'] ?? 'No additions', style: const TextStyle(color: Colors.white70)),
            ),
         ],
      ),
    );
  }

  Widget _buildAlternativesTab(Map<String, dynamic> data) {
    final alts = data['alternatives'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(data['recommendation'] ?? '', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontStyle: FontStyle.italic)),
           const SizedBox(height: 24),
           const Text("Sustainable Alternatives", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
           const SizedBox(height: 16),
           ...alts.map((alt) => Container(
             margin: const EdgeInsets.only(bottom: 12),
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               gradient: LinearGradient(colors: [Colors.greenAccent.withOpacity(0.1), Colors.transparent]),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                   Expanded(child: Text(alt['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                   const SizedBox(width: 8),
                   Text(alt['price_estimate'] ?? '', style: const TextStyle(color: Colors.white70))
                 ]),
                 const SizedBox(height: 8),
                 Text(alt['benefit'] ?? '', style: const TextStyle(color: Colors.grey)),
                 const SizedBox(height: 8),
                 Row(children: [
                   const Icon(Icons.eco, color: Colors.green, size: 16),
                   const SizedBox(width: 4),
                   Expanded(child: Text("Saves ${alt['carbon_savings']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold), overflow: TextOverflow.visible))
                 ])
               ],
             ),
           ))
        ],
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


  Widget _featureButton(BuildContext context, String label, IconData icon, Color color, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }





  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
  }

  Future<void> _loadUserStatus() async {
    final status = await apiService.getUserStatus("user_id_placeholder");
    if (mounted) {
      setState(() {
        _streakDays = status['streak_days'] ?? 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
       return ScannerLoadingWidget(imageBytes: _currentImageBytes);
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40)
             .animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EcoSnap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                 .animate().fadeIn(duration: 600.ms, delay: 200.ms),
                // Tiny Streak Badge if space permits, else in actions
              ],
            )
          ],
        ),
        actions: [
           // Streak Widget
           Container(
             margin: const EdgeInsets.symmetric(vertical: 10),
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange)),
             child: Row(children: [
               const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
               const SizedBox(width: 4),
               Text("$_streakDays", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))
             ]),
           ),
           const SizedBox(width: 8),
           IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))
          ),
           IconButton(
            icon: const Icon(Icons.chat_bubble, color: Colors.greenAccent), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen(userId: "user_id_placeholder"))) 
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70), 
            onPressed: () => context.go('/login')
          )
        ],
      ),
      // ... rest of Scaffold body logic

      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),
          
          // Decorative Circles (2D Elements)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.1)),
            ),
          ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut).then().shimmer(duration: 2.seconds),
          
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.1)),
            ),
          ).animate(delay: 500.ms).scale(duration: 2.seconds, curve: Curves.easeInOut),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  const Text("Snap your room,\nSave the planet.", 
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2))
                    .animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 10),
                  Text("AI-powered analysis to get the best ROI and reduce your carbon footprint.", 
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)))
                    .animate(delay: 400.ms).fadeIn(),
                  
                  const Spacer(),
                  
                  // Glassmorphism Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                      ]
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.camera_alt_outlined, size: 50, color: Colors.greenAccent),
                        const SizedBox(height: 16),
                        const Text("Ready to analyze?", 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                         Text("Upload a clear photo of your living space.", 
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _uploadImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            child: const Text('Start Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 600.ms).slideY(begin: 0.2, end: 0).fadeIn(),
                  
                  const Spacer(),

                  // Quick Access Features
                  SizedBox(
                    height: 90,
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _featureButton(context, "Community", Icons.people, Colors.purple, const CommunityScreen()),
                            _featureButton(context, "Top Picks", Icons.star, Colors.cyanAccent, const TopPicksScreen()),
                            _featureButton(context, "Subsidies", Icons.account_balance, Colors.orange, const SubsidyScreen()),
                            _featureButton(context, "Predictive", Icons.health_and_safety, Colors.redAccent, const MaintenanceScreen()),
                            _featureButton(context, "Carbon", Icons.eco, Colors.green, const CarbonScreen()),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: 700.ms).fadeIn().slideX(),
                  
                  const SizedBox(height: 20),
                  
                  // Bottom Stats
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       Column(children: [Text("250+", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Users", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                       Column(children: [Text("120kg", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("CO2 Saved", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                       Column(children: [Text("4.8★", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text("Rating", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                    ],
                  ).animate(delay: 800.ms).fadeIn(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          // Voice Agent Removed
        ],
      ),
    );
  }
}
