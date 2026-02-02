import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              ),
            ),
          ),
          
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with Animation
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 40)],
                    ),
                    child: Image.asset('assets/images/logo.png'),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3))
                   .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 2.seconds),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'EcoSnap',
                    style: TextStyle(
                      fontFamily: 'Roboto', // Or system default
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Your Personal Al Sustainability Auditor',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 60),
                  
                  // Login Button
                  ElevatedButton(
                    onPressed: () => context.go('/onboarding'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                      shadowColor: Colors.greenAccent.withOpacity(0.4),
                    ),
                    child: const Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ).animate(delay: 800.ms).slideY(begin: 0.2, end: 0).fadeIn(),
                  

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
