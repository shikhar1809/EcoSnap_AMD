import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/leaf_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert'; // For Base64 decoding
import 'dart:typed_data';
import '../widgets/scanner_loading.dart'; // Correct import
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
import '../widgets/verification_dialog.dart';

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
      }

      try {
        final contextResult = await apiService.getAnalysisQuestions(bytes, image.name, userNote: userNote);
        
        if (mounted) {
           setState(() => _isAnalyzing = false);
           
           final verification = contextResult['verification'] ?? {};
           final questions = contextResult['questions'] as List? ?? [];
           final detectedJourney = contextResult['journey_id'] ?? 'SPECIAL';
           
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
                              _showResults(result, bytes, "User Custom");
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
          height: 650, 
          child: Column(
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
                  length: 6,
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
                              Tab(text: "Economics"),
                              Tab(text: "Community"),
                              Tab(text: "Subsidies"),
                              Tab(text: "Top Picks"),
                              Tab(text: "Maintenance"),
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
          Container(
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
                Text("${carbon['total_kg_co2'] ?? '?'} kg CO2", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                 const SizedBox(height: 8),
                const Text("= Planting 50 Trees 🌳", style: TextStyle(color: Colors.green, fontSize: 16)),
                const SizedBox(height: 16),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _impactItem(Icons.directions_car, "3k km", "Driving"),
                    Container(width: 1, height: 30, color: Colors.white10),
                    _impactItem(Icons.power_off, "1 Week", "Off-Grid"),
                  ],
                )
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
          
          if (alts.isNotEmpty) ...[
             const SizedBox(height: 24),
             const Text("Better Alternatives Found!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
             const SizedBox(height: 12),
             ...alts.map((alt) => GestureDetector(
               onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const TopPicksScreen()));
               },
               child: Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white10,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
                 ),
                 child: Row(children: [
                   Container(
                     padding: const EdgeInsets.all(10),
                     decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                     child: const Icon(Icons.shopping_cart, color: Colors.greenAccent),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                       Text(alt['name'] ?? 'Eco Alternative', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       Text("Saves ${alt['carbon_savings']}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                     ])
                   ),
                   const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16)
                 ]),
               ),
             )),
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
                         value: 0.7, 
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
                   child: ListView(
                     children: [
                       ListTile(
                         contentPadding: EdgeInsets.zero,
                         leading: Icon(Icons.circle, size: 8, color: Colors.green),
                         title: Text("Rahul installed Solar Heater", style: TextStyle(color: Colors.white, fontSize: 12)),
                         trailing: Text("2m ago", style: TextStyle(color: Colors.grey, fontSize: 10)),
                       ),
                       ListTile(
                         contentPadding: EdgeInsets.zero,
                         leading: Icon(Icons.circle, size: 8, color: Colors.blue),
                         title: Text("Priya bought Bamboo Kit", style: TextStyle(color: Colors.white, fontSize: 12)),
                         trailing: Text("15m ago", style: TextStyle(color: Colors.grey, fontSize: 10)),
                       ),
                       ListTile(
                         contentPadding: EdgeInsets.zero,
                         leading: Icon(Icons.circle, size: 8, color: Colors.orange),
                         title: Text("Amit audited Living Room", style: TextStyle(color: Colors.white, fontSize: 12)),
                         trailing: Text("1h ago", style: TextStyle(color: Colors.grey, fontSize: 10)),
                       ),
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
                 child: Text("${data['efficiency_score'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
               )
            ],
          ),
          const SizedBox(height: 24),
          _infoCard(Icons.home, "Room Rating", "${data['efficiency_score']}/100", "Based on appliances & layout"),

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
    return const Center(child: Text("Appliances Tab", style: TextStyle(color: Colors.white)));
  }

  Widget _buildGreenArchitectureTab(Map<String, dynamic> data) {
    return const Center(child: Text("Architecture Tab", style: TextStyle(color: Colors.white)));
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
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withOpacity(0.5))
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text("Leaderboard", style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                 Text("Level 3", style: TextStyle(color: Colors.white)),
                                 SizedBox(width: 4),
                                 Icon(Icons.stars, color: Colors.amber, size: 16)
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                Expanded(
                  child: _isAnalyzing 
                  ? const ScannerLoadingWidget() 
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // FIX: Ensure full width
                      children: [
                        const SizedBox(height: 20),
                        
                        Center(
                          child: GestureDetector(
                            onTap: _uploadImage,
                            child: Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.greenAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.1)],
                                ),
                                border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)
                                ]
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt, size: 50, color: Colors.white),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text("Tap to Scan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                  const Text("Analyze Footprint", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Align(alignment: Alignment.centerLeft, child: Text("Explore", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                                ),
                                const SizedBox(height: 16),
                                
                                SizedBox(
                                  height: 120, 
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.only(left: 20, right: 240),
                                    children: [
                                      _featureButton(context, "Community", Icons.people, Colors.purpleAccent, const CommunityScreen()),
                                      _featureButton(context, "Marketplace", Icons.store, Colors.pinkAccent, const MarketplaceScreen()),
                                      _featureButton(context, "Carbon", Icons.cloud, Colors.tealAccent, const CarbonScreen()),
                                      _featureButton(context, "Office Snap", Icons.business, Colors.orange, const OfficeSnapScreen()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: 0,
                              top: -40,
                              child: SizedBox(
                                width: 300,
                                child: VoiceAgentWidget(analysisContext: _lastAnalysisData)
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _dashboardCard("Did you know?", "Switching to LEDs saves ₹200/mo.", "Details", Icons.lightbulb, Colors.yellowAccent, () {}),
                              const SizedBox(width: 12),
                              _dashboardCard("Daily Challenge", "Find one green alternative today.", "Start", Icons.camera_outdoor, Colors.green, () => _uploadImage()),
                              const SizedBox(width: 12),
                              _dashboardCard("Maintenance", "Check AC Filter for efficiency.", "Check", Icons.build, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaintenanceScreen()))),
                              const SizedBox(width: 12),
                              _dashboardCard("Top Picks", "Best rated eco products.", "View", Icons.star, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TopPicksScreen()))),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        // VoiceAgent moved to Explore section
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _dashboardCard(String title, String subtitle, String action, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]
            )
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: onTap, 
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(action, style: TextStyle(color: color, fontSize: 12))
          )
        ],
      ),
    );
  }
}
