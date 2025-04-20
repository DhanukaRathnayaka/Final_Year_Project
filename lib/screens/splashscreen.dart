import 'package:flutter/material.dart';
import 'package:safespace/screens/welcome_screen.dart';
import 'package:safespace/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore_for_file: use_build_context_synchronously



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2)); // Optional loading time

    final prefs = await SharedPreferences.getInstance();
    final showHome = prefs.getBool('onboardingComplete') ?? false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => showHome ? const WelcomeScreen() : const ChatOnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/app.png',
          height: 150,
        ),
      ),
    );
  }
}
