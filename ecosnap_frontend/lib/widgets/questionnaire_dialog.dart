import 'package:flutter/material.dart';

class QuestionnaireDialog extends StatefulWidget {
  final List<dynamic> questions;
  final Function(Map<String, dynamic>) onSubmit;

  const QuestionnaireDialog({super.key, required this.questions, required this.onSubmit});

  @override
  State<QuestionnaireDialog> createState() => _QuestionnaireDialogState();
}

class _QuestionnaireDialogState extends State<QuestionnaireDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    for (var q in widget.questions) {
      // Default to 'text' if type is missing
      final type = q['type'] ?? 'text';
      
      if (type == 'text' || type == 'number') {
        _controllers[q['id']] = TextEditingController();
      }
      // Initialize Selects
      if (q['type'] == 'select' && (q['options'] as List).isNotEmpty) {
        _answers[q['id']] = q['options'][0];
      }
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: [
             BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("EcoSnap Context", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey))
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            
            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     const Text("Help us customize your report:", style: TextStyle(color: Colors.white70, fontSize: 13)),
                     const SizedBox(height: 16),
                     ...widget.questions.map((q) => _buildQuestionField(q)),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Colors.white10),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent, 
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16)
                  ),
                  onPressed: () {
                    print('[QUESTIONNAIRE] User clicked Run Analysis');
                    // Collect Text Answers
                    _controllers.forEach((id, controller) {
                      _answers[id] = controller.text;
                    });
                    print('[QUESTIONNAIRE] Collected answers: $_answers');
                    // Close dialog FIRST, then trigger analysis
                    Navigator.pop(context);
                    print('[QUESTIONNAIRE] Calling onSubmit callback...');
                    widget.onSubmit(_answers);
                  },
                  child: const Text("Run Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionField(dynamic input) {
    // Safe cast to avoid LinkedMap subtype errors
    final Map<String, dynamic> q = Map<String, dynamic>.from(input as Map);
    final type = q['type'] ?? 'text'; // Default to text

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q['text'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          if (type == 'text' || type == 'number')
            TextField(
              controller: _controllers[q['id']],
              keyboardType: type == 'number' ? TextInputType.number : TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black54, // Darker background for contrast
                hintText: "Type here...",
                hintStyle: const TextStyle(color: Colors.white30),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.greenAccent)),
              ),
            )
          else if (q['type'] == 'select')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _answers[q['id']],
                  dropdownColor: Colors.grey.shade900,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: (q['options'] as List).map<DropdownMenuItem<String>>((opt) {
                    return DropdownMenuItem<String>(
                      value: opt, 
                      child: Text(opt, style: const TextStyle(color: Colors.white))
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _answers[q['id']] = val;
                      print("Selected: $val"); // Debug print
                    });
                  },
                ),
              ),
            )
        ],
      ),
    );
  }
}
