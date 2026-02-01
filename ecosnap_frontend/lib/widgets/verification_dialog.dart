import 'package:flutter/material.dart';

class VerificationDialog extends StatefulWidget {
  final Map<String, dynamic> verificationData;
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
      'icon': '☀️',
      'name': 'Solar Potential Scanner',
      'desc': 'Rooftop analysis, panel placement, subsidies',
      'color': Colors.orange,
    },
    'ROOM_ENERGY': {
      'icon': '🛋️',
      'name': 'Room Energy Audit',
      'desc': 'Appliance efficiency, vampire power detection',
      'color': Colors.blue,
    },
    'PRODUCT_SCAN': {
      'icon': '♻️',
      'name': 'Product Lifecycle Scan',
      'desc': 'Carbon footprint, green alternatives',
      'color': Colors.green,
    },
    'BILL_OCR': {
      'icon': '📄',
      'name': 'Bill Buster Analysis',
      'desc': 'Tariff breakdown, reduction strategies',
      'color': Colors.purple,
    },
    'FOOD_AUDIT': {
      'icon': '🍎',
      'name': 'Food Carbon Audit',
      'desc': 'Meal impact, greener swaps',
      'color': Colors.red,
    },
    'VEHICLE_CHECK': {
      'icon': '🚗',
      'name': 'Vehicle Sustainability',
      'desc': 'Emissions analysis, EV comparison',
      'color': Colors.teal,
    },
    'SPECIAL': {
      'icon': '✨',
      'name': 'General Analysis',
      'desc': 'Custom sustainability insights',
      'color': Colors.grey,
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
    
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: Colors.blueAccent),
            const SizedBox(width: 10),
            const Text("Smart Triage", style: TextStyle(color: Colors.white, fontSize: 18))
          ]),
          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConfidenceColor(widget.confidence).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getConfidenceColor(widget.confidence)),
            ),
            child: Text(
              "${(widget.confidence * 100).toInt()}%",
              style: TextStyle(
                color: _getConfidenceColor(widget.confidence),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEditing) ...[
              // AI Question
              Text(question, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              
              const SizedBox(height: 20),
              
              // Detected Object Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (journeyData['color'] as Color).withOpacity(0.3),
                      Colors.black26,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (journeyData['color'] as Color).withOpacity(0.5)),
                ),
                child: Column(children: [
                  Text(
                    "${journeyData['icon']} $cat",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    journeyData['desc'] as String,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),

              const SizedBox(height: 16),
              
              // Journey Selector
              const Text("Analysis Type:", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              const SizedBox(height: 8),
              
              // Journey Cards (horizontal scroll)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _journeyInfo.entries.map((e) {
                    final isSelected = e.key == _selectedJourneyId;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedJourneyId = e.key),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? (e.value['color'] as Color).withOpacity(0.3) 
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? (e.value['color'] as Color) 
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e.value['icon'] as String, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              (e.value['name'] as String).split(' ').first,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white54,
                                fontSize: 10,
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

              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.orangeAccent),
                    label: const Text("Wrong?", style: TextStyle(color: Colors.orangeAccent)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => widget.onResult(true, null, _selectedJourneyId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: journeyData['color'] as Color,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                    label: const Text("Analyze", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ] else ...[
              // Correction Mode
              const Text("What is this?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _correctionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "E.g., Solar panel on roof, Old ceiling fan",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text("Back", style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_correctionController.text.isNotEmpty) {
                           widget.onResult(false, _correctionController.text, _selectedJourneyId);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text("Continue", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}
