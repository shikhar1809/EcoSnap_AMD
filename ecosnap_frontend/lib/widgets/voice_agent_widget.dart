import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceAgentWidget extends StatefulWidget {
  final Map<String, dynamic> analysisContext;

  const VoiceAgentWidget({
    super.key, 
    required this.analysisContext,
  });

  @override
  State<VoiceAgentWidget> createState() => _VoiceAgentWidgetState();
}

enum AgentState { idle, listening, processing, speaking }

class _VoiceAgentWidgetState extends State<VoiceAgentWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();

  AgentState _state = AgentState.idle;
  String _transcription = "";
  String _agentResponse = "";
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAudio();
  }

  void _initSpeech() async {
    try {
      _available = await _speech.initialize(
        onError: (val) {
           debugPrint("STT Error: $val");
           if (_state == AgentState.listening) {
             setState(() {
               _state = AgentState.idle;
               _transcription = ""; 
             });
           }
        },
        onStatus: (val) {
          debugPrint("STT Status: $val");
        },
      );
    } catch (e) {
      debugPrint("STT Init Failed: $e");
    }
  }

  void _initAudio() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _state = AgentState.idle);
    });
  }

  void _startListening() async {
    if (!_available) {
      await _speech.initialize(); 
    }
    
    await _audioPlayer.stop(); // Stop any speaking

    setState(() {
      _state = AgentState.listening;
      _transcription = "Listening...";
      _agentResponse = "";
    });

    _speech.listen(
      onResult: (val) {
        setState(() => _transcription = val.recognizedWords);
      },
      localeId: "en_IN",
      pauseFor: const Duration(seconds: 5), // Wait longer for pause
      listenFor: const Duration(seconds: 30),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    // If we have some text, process it. If empty, just go idle.
    if (_transcription.isNotEmpty && _transcription != "Listening...") {
        _processQuery(_transcription);
    } else {
        setState(() => _state = AgentState.idle);
    }
  }

  Future<void> _processQuery(String query) async {
    setState(() => _state = AgentState.processing);

    try {
      final contextStr = "Room Analysis Data: ${widget.analysisContext.toString()}";
      final result = await _apiService.askAdvisor("user_voice", query, context: contextStr);
      
      final answer = result['response'] ?? "I could not understand.";
      final audioBase64 = result['audio'];

      if (mounted) {
        setState(() {
          _state = AgentState.speaking;
          _agentResponse = answer;
        });
        
        if (audioBase64 != null) {
          final bytes = base64Decode(audioBase64);
          await _audioPlayer.play(BytesSource(bytes));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
           _state = AgentState.idle;
           _agentResponse = "Connection Error.";
        });
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a Stack to allow the bubble to appear "outside" the button flow if needed,
    // but here we just return the positioned elements (Widget should be used in a Stack).
    // Note: This widget assumes it's placed inside a Stack with Positioned.fill or similar,
    // OR we explicitly position the elements here.
    // Let's assume the Parent uses Stack, so we just return the aligned content.
    
    return Stack(
      alignment: Alignment.bottomRight,
      fit: StackFit.loose,
      children: [
        
        // Transcription bubble (Only visible when active)
        if (_state != AgentState.idle)
          Positioned(
            bottom: 140, 
            right: 20,
            left: 20, // Constrain width
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _state == AgentState.speaking ? _agentResponse : _transcription,
                    style: TextStyle(
                      fontSize: 16, 
                      color: _state == AgentState.speaking ? Colors.black87 : Colors.blueGrey,
                      fontWeight: FontWeight.w500
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_state == AgentState.processing)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: LinearProgressIndicator(color: Colors.greenAccent),
                    )
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          ),

        // THE FAB (Avatar)
        Positioned(
          bottom: 20,
          right: 20,
          child: Listener(
            onPointerDown: (_) => _startListening(),
            onPointerUp: (_) => _stopListening(),
            child: AvatarGlow(
              animate: _state == AgentState.listening || _state == AgentState.speaking,
              glowColor: _state == AgentState.listening ? Colors.blue : Colors.green,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.2), 
                  border: Border.all(
                    color: _getColorForState(_state), 
                    width: 4
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage(_getImageForState(_state)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForState(AgentState state) {
    if (state == AgentState.listening) return Colors.blueAccent;
    if (state == AgentState.speaking) return Colors.green;
    if (state == AgentState.processing) return Colors.orange;
    return Colors.grey;
  }

  String _getImageForState(AgentState state) {
    if (state == AgentState.listening) return 'assets/images/listening.png';
    if (state == AgentState.speaking) return 'assets/images/speaking.png';
    return 'assets/images/idle.png';
  }
}
