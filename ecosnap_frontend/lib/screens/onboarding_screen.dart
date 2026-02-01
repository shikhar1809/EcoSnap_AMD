import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Data
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String _selectedLanguage = "en_IN";
  
  final Map<String, String> _languages = {
    "English": "en_IN",
    "Hindi (हिंदी)": "hi_IN",
    "Tamil (தமிழ்)": "ta_IN",
    "Telugu (తెలుగు)": "te_IN",
    "Kannada (ಕನ್ನಡ)": "kn_IN",
    "Bengali (বাংলা)": "bn_IN"
  };

  @override
  void dispose() {
    _pageController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pincode', _pincodeController.text);
    await prefs.setString('user_city', _cityController.text);
    await prefs.setString('user_language', _selectedLanguage);
    await prefs.setBool('is_onboarded', true);

    if (mounted) {
      context.go('/');
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (_pincodeController.text.isEmpty || _cityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in your location details.")));
        return;
      }
    }
    _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: Stack(
        children: [
          // Background Elements
           Positioned(
             top: -100, right: -100,
             child: Container(
               width: 300, height: 300,
               decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent.withOpacity(0.1)),
             ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2), duration: 4.seconds),
           ),
           Positioned(
             bottom: -50, left: -50,
             child: Container(
               width: 200, height: 200,
               decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.1)),
             ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 5.seconds),
           ),

           SafeArea(
             child: Column(
               children: [
                 const SizedBox(height: 20),
                 // Progress Indicator
                 Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: List.generate(3, (index) => 
                     AnimatedContainer(
                       duration: 300.ms,
                       margin: const EdgeInsets.symmetric(horizontal: 4),
                       width: _currentPage == index ? 30 : 10,
                       height: 10,
                       decoration: BoxDecoration(
                         color: _currentPage >= index ? Colors.greenAccent : Colors.grey.withOpacity(0.3),
                         borderRadius: BorderRadius.circular(5)
                       ),
                     )
                   ),
                 ),
                 const SizedBox(height: 20),
                 
                 Expanded(
                   child: PageView(
                     controller: _pageController,
                     physics: const NeverScrollableScrollPhysics(),
                     onPageChanged: (idx) => setState(() => _currentPage = idx),
                     children: [
                       _buildLocationStep(),
                       _buildLanguageStep(),
                       _buildFinalStep(),
                     ],
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Where are you based?", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text("We use this to show you neighborhood challenges and local insights.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 40),
          
          TextField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Pincode",
              labelStyle: const TextStyle(color: Colors.greenAccent),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.pin_drop, color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _cityController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "City",
              labelStyle: const TextStyle(color: Colors.greenAccent),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.location_city, color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
               // Mock Geolocation
               setState(() {
                 _pincodeController.text = "400050";
                 _cityController.text = "Mumbai";
               });
            }, 
            icon: const Icon(Icons.my_location), 
            label: const Text("Use Current Location"),
            style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          ),
          
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
              child: const Text("Next"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose your voice", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text("Select a language for your AI assistant.", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 40),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _languages.entries.map((e) {
              final isSelected = _selectedLanguage == e.value;
              return ChoiceChip(
                label: Text(e.key),
                selected: isSelected,
                selectedColor: Colors.greenAccent,
                backgroundColor: Colors.greenAccent.withOpacity(0.8), // Lighter background for black text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isSelected ? Colors.greenAccent : Colors.greenAccent.withOpacity(0.5)),
                ),
                labelStyle: const TextStyle(
                  color: Colors.black, // Always black for visibility
                  fontWeight: FontWeight.bold
                ),
                onSelected: (val) => setState(() => _selectedLanguage = e.value),
              );
            }).toList(),
          ),
          
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               TextButton(onPressed: () => _pageController.previousPage(duration: 300.ms, curve: Curves.ease), child: const Text("Back", style: TextStyle(color: Colors.white70))),
               ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                child: const Text("Next"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFinalStep() {
     return Padding(
       padding: const EdgeInsets.all(32.0),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Container(
             padding: const EdgeInsets.all(30),
             decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent.withOpacity(0.2)),
             child: const Icon(Icons.check, size: 80, color: Colors.greenAccent),
           ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
           
           const SizedBox(height: 30),
           Text("You're all set!", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)).animate().fadeIn(delay: 300.ms),
           const SizedBox(height: 10),
           Text("Analyzing $_selectedLanguage content for ${_cityController.text}...", style: const TextStyle(color: Colors.white70)).animate().fadeIn(delay: 500.ms),
           
           const SizedBox(height: 60),
           ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67EDAC), 
                foregroundColor: Colors.black, 
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text("START SAVING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate().slideY(begin: 0.2, end: 0, delay: 700.ms).fadeIn(),
         ],
       ),
     );
  }
}
