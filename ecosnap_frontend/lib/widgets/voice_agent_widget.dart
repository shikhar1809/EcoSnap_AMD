import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _selectedLocale = "en_IN";
  
  final Map<String, String> _languages = {
    "English": "en_IN",
    "Hindi": "hi_IN",
    "Tamil": "ta_IN",
    "Telugu": "te_IN",
    "Kannada": "kn_IN",
    "Bengali": "bn_IN"
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initSpeech();
    _initAudio();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('user_language');
    if (lang != null && mounted) {
      setState(() => _selectedLocale = lang);
    }
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


    // Simulate language switching for TTS/STT if needed, though STT supports locale.
    _speech.listen(
      onResult: (val) {
        setState(() => _transcription = val.recognizedWords);
      },
      localeId: _selectedLocale,
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
      
      var answer = result['response'] ?? "I could not understand.";
      
      // MOCK TRANSLATION LOGIC (For MVP Demo)
      if (_selectedLocale == "hi_IN") {
          answer = "नमस्ते! मैंने आपके कमरे का विश्लेषण किया है। एलईडी बल्ब लगाने से आप ₹200 बचा सकते हैं।";
      } else if (_selectedLocale == "ta_IN") {
          answer = "வணக்கம்! உங்கள் அறையை ஆய்வு செய்தேன். எல்.ஈ.டி விளக்குகள் மூலம் நீங்கள் ₹200 சேமிக்கலாம்.";
      }

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
    return SizedBox(
      height: 250, // Enforce height so it doesn't collapse
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Language Selector
          Positioned(
            bottom: 125,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30)),
              child: DropdownButton<String>(
                value: _selectedLocale,
                dropdownColor: Colors.grey.shade900,
                underline: const SizedBox(),
                icon: const Icon(Icons.language, color: Colors.white, size: 16),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedLocale = val);
                },
                items: _languages.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key))).toList(),
              ),
            ),
          ),
          
          // Transcription bubble
          if (_state != AgentState.idle)
            Positioned(
              bottom: 140, 
              right: 20,
              left: 20,
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
            right: 0, // Align to right edge of the container
            child: Listener(
              onPointerDown: (_) => _startListening(),
              onPointerUp: (_) => _stopListening(),
              child: AvatarGlow(
                animate: _state == AgentState.listening || _state == AgentState.speaking,
                glowColor: _state == AgentState.listening ? Colors.blue : Colors.green,
                duration: const Duration(milliseconds: 2000),
                repeat: true,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5), 
                    border: Border.all(
                      color: _getColorForState(_state), 
                      width: 4
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _getImageForState(_state),
                      fit: BoxFit.cover,
                    ),
                  )
                ),
              ),
            ),
          ),
        ],
      ),
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
    if (state == AgentState.processing) return 'assets/images/listening.png';
    return 'assets/images/idle.png';
  }
}
