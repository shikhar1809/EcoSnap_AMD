import 'package:flutter/material.dart';

class VerificationDialog extends StatefulWidget {
  final Map<String, dynamic> verificationData;
  final String detectedJourneyId;
  final Function(bool isConfirmed, String? correctedCategory, String finalJourneyId) onResult;

  const VerificationDialog({
    super.key, 
    required this.verificationData,
    required this.detectedJourneyId,
    required this.onResult
  });

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<VerificationDialog> {
  final TextEditingController _correctionController = TextEditingController();
  bool _isEditing = false;
  late String _selectedJourneyId;

  // Journey Map for UI display
  final Map<String, String> _journeyDisplayNames = {
    'FIND_ALTERNATIVE': '♻️ Green Alternative Finder',
    'SPACE_AUDIT': '🔍 Space Carbon Audit',
    'SPACE_PLANNING': '🏗️ Green Workspace Planner',
    'BILL_ANALYSIS': '📄 Bill Buster Analysis',
    'SPECIAL': '✨ Special Request'
  };

  @override
  void initState() {
    super.initState();
    _selectedJourneyId = widget.detectedJourneyId;
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.verificationData['detected_category'] ?? 'Item';
    final question = widget.verificationData['question'] ?? 'Is this correct?';
    
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Icon(Icons.verified_user, color: Colors.blueAccent),
            const SizedBox(width: 10),
            const Text("Smart Triage", style: TextStyle(color: Colors.white, fontSize: 18))
          ]),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38),
            onPressed: () => Navigator.pop(context),
            tooltip: "Close",
          )
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEditing) ...[
              Text(question, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              
              const SizedBox(height: 20),
              
              // Detected Object Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Text(cat, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text("Detected Item", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),

              // Detected Journey Selector
              const Text("Analysis Mode:", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black26, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5))
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: Colors.grey.shade800,
                    value: _selectedJourneyId,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                    items: _journeyDisplayNames.entries.map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedJourneyId = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text("Wrong Item?", style: TextStyle(color: Colors.orangeAccent)),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onResult(true, null, _selectedJourneyId),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Start Analysis", style: TextStyle(color: Colors.white)),
                  )
                ],
              )
            ] else ...[
              // Correction Mode (same as before)
              const Text("What is this item?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _correctionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "E.g., Vintage Rolex 1980",
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_correctionController.text.isNotEmpty) {
                       widget.onResult(false, _correctionController.text, _selectedJourneyId);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("Continue with this Item", style: TextStyle(color: Colors.white)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
