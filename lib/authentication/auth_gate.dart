import 'package:flutter/material.dart';
import 'package:safespace/navmanager.dart';
import 'package:safespace/screens/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is authenticated
        final session = snapshot.data?.session;
        
        if (session != null) {
          // User is logged in - go to home
          return const NavManager(isGuest: false);
        } else {
          // User not logged in - go to onboarding screen
          return const OnboardingScreen();
        }
      },
    );
  }
}