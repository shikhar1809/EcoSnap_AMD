import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class VerificationDialog extends StatefulWidget {
  final Map verificationData;
  final String detectedJourneyId;
  final double confidence;
  final bool autoProceeed;
  final Function(bool isConfirmed, String? correctedCategory, String finalJourneyId) onResult;

  const VerificationDialog({
    super.key, 
    required this.verificationData,
    required this.detectedJourneyId,
    this.confidence = 0.5,
    this.autoProceeed = false,
    required this.onResult
  });

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  final TextEditingController _correctionController = TextEditingController();
  bool _isEditing = false;
  late String _selectedJourneyId;

  // Journey Map with icons and descriptions
  final Map<String, Map<String, dynamic>> _journeyInfo = {
    'SOLAR_AUDIT': {
      'iconData': Icons.wb_sunny_rounded,
      'name': 'Solar Potential Scanner',
      'desc': 'Rooftop analysis, panel placement',
      'color': Colors.orange,
    },
    'WIND_ANALYSIS': {
      'iconData': Icons.air_rounded,
      'name': 'Wind Energy Assessor',
      'desc': 'Turbine viability check',
      'color': Colors.cyan,
    },
    'ROOM_ENERGY': {
      'iconData': Icons.chair_rounded,
      'name': 'Room Energy Audit',
      'desc': 'Appliance efficiency check',
      'color': Colors.blue,
    },
    'PRODUCT_SCAN': {
      'iconData': Icons.qr_code_scanner_rounded,
      'name': 'Product Lifecycle Scan',
      'desc': 'Carbon footprint analysis',
      'color': Colors.green,
    },
    'BILL_OCR': {
      'iconData': Icons.receipt_long_rounded,
      'name': 'Bill Buster Analysis',
      'desc': 'Tariff reduction strategies',
      'color': Colors.purple,
    },
    'FOOD_AUDIT': {
      'iconData': Icons.restaurant_menu_rounded,
      'name': 'Food Carbon Audit',
      'desc': 'Meal impact & greener swaps',
      'color': Colors.red,
    },
    'VEHICLE_CHECK': {
      'iconData': Icons.directions_car_rounded,
      'name': 'Vehicle Sustainability',
      'desc': 'Emissions & EV comparison',
      'color': Colors.teal,
    },
    'SPECIAL': {
      'iconData': Icons.auto_awesome_rounded,
      'name': 'General Analysis',
      'desc': 'Custom sustainability insights',
      'color': Colors.deepPurple,
    },
  };

  @override
  void initState() {
    super.initState();
    // Safety check for unknown journey IDs
    if (_journeyInfo.containsKey(widget.detectedJourneyId)) {
      _selectedJourneyId = widget.detectedJourneyId;
    } else {
      _selectedJourneyId = 'SPECIAL';
      debugPrint("Warning: Unknown journey ID '${widget.detectedJourneyId}', defaulting to SPECIAL.");
    }
  }

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.8) return Colors.green;
    if (conf >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.verificationData['detected_category'] ?? 'Item';
    final question = widget.verificationData['question'] ?? 'Is this what you want to analyze?';
    final journeyData = _journeyInfo[_selectedJourneyId]!;
    
    return Dialog(
      backgroundColor: Colors.transparent, // Transparent for custom gradient
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade900,
              const Color(0xFF1E1E2C),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: (journeyData['color'] as Color).withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with animation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: const Text(
                          "Smart Triage", 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ]),
                  ),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(widget.confidence).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getConfidenceColor(widget.confidence).withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined, 
                          size: 14, 
                          color: _getConfidenceColor(widget.confidence)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${(widget.confidence * 100).toInt()}% Confidence",
                          style: TextStyle(
                            color: _getConfidenceColor(widget.confidence),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              if (!_isEditing) ...[
                // AI Question
                Text(
                  question, 
                  style: const TextStyle(
                    color: Colors.white70, 
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Hero Detected Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (journeyData['color'] as Color).withOpacity(0.2),
                        (journeyData['color'] as Color).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (journeyData['color'] as Color).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (journeyData['color'] as Color).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (journeyData['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: (journeyData['color'] as Color).withOpacity(0.5)),
                        ),
                        child: Icon(
                          journeyData['iconData'] as IconData,
                          size: 32,
                          color: (journeyData['color'] as Color),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontSize: 22, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              journeyData['desc'] as String,
                              style: TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Journey Selector Headers
                const Text(
                  "ANALYSIS TYPES", 
                  style: TextStyle(
                    color: Colors.white38, 
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 1.2
                  )
                ),
                const SizedBox(height: 12),
                
                // Journey Cards (Horizontal Scroll)
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: _journeyInfo.entries.map((e) {
                      final isSelected = e.key == _selectedJourneyId;
                      final color = e.value['color'] as Color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedJourneyId = e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 85,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                e.value['iconData'] as IconData, 
                                size: 28,
                                color: isSelected ? color : Colors.white54,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (e.value['name'] as String).split(' ').first,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white38,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),
                
                // Action buttons
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white54),
                      label: const Text("Refine", style: TextStyle(color: Colors.white54)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (journeyData['color'] as Color).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // ... implementation from earlier ...
                          print('[VERIFICATION] User clicked Analyze button');
                          widget.onResult(true, null, _selectedJourneyId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: journeyData['color'] as Color, // Dynamic color
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text(
                          "Start Analysis", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  ],
                )
              ] else ...[
                // Correction Mode (Premium Visuals)
                Text(
                  "What is this object?", 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  )
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _correctionController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "E.g., Solar panel on roof, Old ceiling fan",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Back"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_correctionController.text.isNotEmpty) {
                             widget.onResult(false, _correctionController.text, _selectedJourneyId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 8,
                          shadowColor: Colors.blueAccent.withOpacity(0.5),
                        ),
                        child: const Text("Continue", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
