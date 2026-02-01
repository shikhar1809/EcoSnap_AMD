import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

/// EcoAdvisor Voice Agent Widget
/// "Hey Eco" voice-activated sustainability assistant
/// Winner-level feature: Personalized AI Twin with voice control
class EcoAdvisorWidget extends StatefulWidget {
  final Function(String command)? onCommand;
  final Function()? onScanRequested;
  
  const EcoAdvisorWidget({
    super.key,
    this.onCommand,
    this.onScanRequested,
  });

  @override
  State<EcoAdvisorWidget> createState() => _EcoAdvisorWidgetState();
}

class _EcoAdvisorWidgetState extends State<EcoAdvisorWidget> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  String _transcript = "";
  String _response = "";
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Sample responses for demo
  final Map<String, String> _demoResponses = {
    "carbon footprint": "🌍 Your weekly carbon footprint is 12.3 kg CO₂. That's 15% lower than last week! Great job using public transport.",
    "scan": "📸 Opening scanner... Point your camera at any product, room, or bill!",
    "solar": "☀️ Based on your location in Mumbai, solar panels could save you ₹2,800/month. Want me to analyze your rooftop?",
    "save energy": "⚡ Quick tips: 1) Switch to LED bulbs - saves 80% 2) Unplug chargers - stops vampire power 3) Use AC at 24°C",
    "subsidy": "💰 You're eligible for PM Surya Ghar subsidy of ₹78,000. I can help you apply!",
    "default": "🤖 I'm your EcoAdvisor! Ask me about your carbon footprint, energy savings, solar potential, or say 'scan' to analyze something.",
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _transcript = "";
      _response = "";
    });
    _pulseController.repeat(reverse: true);
    
    // Simulate voice recognition (in production, use speech_to_text package)
    Timer(const Duration(seconds: 2), () {
      if (mounted && _isListening) {
        _simulateVoiceInput();
      }
    });
  }

  void _stopListening() {
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isListening = false;
    });
  }

  void _simulateVoiceInput() {
    // Demo: Randomly select a command
    final commands = ["What's my carbon footprint?", "Scan something", "Tell me about solar", "How to save energy?"];
    final command = commands[Random().nextInt(commands.length)];
    
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _transcript = command;
    });
    _pulseController.stop();
    
    // Process after short delay
    Timer(const Duration(milliseconds: 800), () {
      _processCommand(command);
    });
  }

  void _processCommand(String command) {
    String response = _demoResponses["default"]!;
    
    final lower = command.toLowerCase();
    if (lower.contains("carbon") || lower.contains("footprint")) {
      response = _demoResponses["carbon footprint"]!;
    } else if (lower.contains("scan")) {
      response = _demoResponses["scan"]!;
      widget.onScanRequested?.call();
    } else if (lower.contains("solar")) {
      response = _demoResponses["solar"]!;
    } else if (lower.contains("energy") || lower.contains("save")) {
      response = _demoResponses["save energy"]!;
    } else if (lower.contains("subsidy")) {
      response = _demoResponses["subsidy"]!;
    }
    
    setState(() {
      _isProcessing = false;
      _response = response;
    });
    
    widget.onCommand?.call(command);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Main voice button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isListening 
                        ? [Colors.redAccent.withOpacity(0.3), Colors.orangeAccent.withOpacity(0.3)]
                        : [Colors.greenAccent.withOpacity(0.15), Colors.tealAccent.withOpacity(0.15)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isListening ? Colors.redAccent : Colors.greenAccent.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: _isListening ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isListening
                              ? [Colors.redAccent, Colors.orangeAccent]
                              : [Colors.greenAccent, Colors.tealAccent],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isListening 
                                ? "Listening..." 
                                : _isProcessing 
                                  ? "Processing..."
                                  : "Hey Eco! 👋",
                              style: TextStyle(
                                color: _isListening ? Colors.redAccent : Colors.greenAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isListening 
                                ? "Say something like 'What's my carbon footprint?'"
                                : "Tap to talk to your EcoAdvisor",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isListening && !_isProcessing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "AI",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (_isListening)
                        _buildWaveform(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Transcript / Response area
          if (_transcript.isNotEmpty || _response.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_transcript.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(
                          "You: $_transcript",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_response.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🤖", style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _response,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_isProcessing)
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Thinking...",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeInOut,
          builder: (context, value, child) => Container(
            width: 3,
            height: 15 * value * Random().nextDouble().clamp(0.5, 1.0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Compact voice button for embedding
class MiniVoiceButton extends StatelessWidget {
  final VoidCallback? onTap;
  
  const MiniVoiceButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent.withOpacity(0.3), Colors.tealAccent.withOpacity(0.3)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.2),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.greenAccent, size: 20),
      ),
    );
  }
}
