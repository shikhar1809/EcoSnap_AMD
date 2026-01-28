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
      if (q['type'] == 'text' || q['type'] == 'number') {
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
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("ScanCarbon Context", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text("Help us customize your report:", style: TextStyle(color: Colors.grey, fontSize: 13)),
             const SizedBox(height: 16),
             ...widget.questions.map((q) => _buildQuestionField(q)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text("Cancel", style: TextStyle(color: Colors.grey))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
          onPressed: () {
            // Collect Text Answers
            _controllers.forEach((id, controller) {
              _answers[id] = controller.text;
            });
            widget.onSubmit(_answers);
            Navigator.pop(context);
          },
          child: const Text("Analyze"),
        )
      ],
    );
  }

  Widget _buildQuestionField(Map<String, dynamic> q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q['text'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (q['type'] == 'text' || q['type'] == 'number')
            TextField(
              controller: _controllers[q['id']],
              keyboardType: q['type'] == 'number' ? TextInputType.number : TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                hintText: "Type here...",
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            )
          else if (q['type'] == 'select')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: DropdownButton<String>(
                value: _answers[q['id']],
                dropdownColor: Colors.grey.shade800,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white),
                items: (q['options'] as List).map<DropdownMenuItem<String>>((opt) {
                  return DropdownMenuItem<String>(value: opt, child: Text(opt));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _answers[q['id']] = val;
                  });
                },
              ),
            )
        ],
      ),
    );
  }
}
