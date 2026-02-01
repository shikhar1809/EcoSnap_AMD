import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String? initialContext;

  const ChatScreen({super.key, required this.userId, this.initialContext});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<Map<String, String>> _messages = []; // {role: user/ai, text: ...}
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Namaste! I am your EcoSnap Advisor. How can I help you save money and energy today?'
    });
    if (widget.initialContext != null) {
        _sendMessage("I need advice regarding: ${widget.initialContext}", silent: true);
    }
  }

  Future<void> _sendMessage(String text, {bool silent = false}) async {
    if (text.trim().isEmpty) return;

    if (!silent) {
      setState(() {
        _messages.add({'role': 'user', 'text': text});
        _isLoading = true;
      });
      _controller.clear();
    }

    // Call API
    final result = await _apiService.askAdvisor(widget.userId, text, context: widget.initialContext ?? "");
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add({'role': 'ai', 'text': result['response'] ?? "I'm having trouble connecting right now."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Green Advisor", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            tooltip: "Back to Home",
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.greenAccent : Colors.grey.shade800,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.black87 : Colors.white),
                    ),
                  ).animate().fade().slideY(begin: 0.2, end: 0, duration: 300.ms),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Thinking...", style: TextStyle(color: Colors.greenAccent)),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Ask about ACs, ROI, or solar...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.greenAccent),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
