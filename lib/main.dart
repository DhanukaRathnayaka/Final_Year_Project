import 'package:flutter/material.dart';
import 'package:safespace/config.dart';
import 'package:safespace/navmanager.dart';
import 'package:safespace/screens/chatbot.dart';
import 'package:safespace/authentication/sign_up.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/authentication/auth_gate.dart';
import 'package:safespace/authentication/login_page.dart';
import 'package:safespace/services/mental_state_service.dart';

// Add this to your main.dart or create a service locator
MentalStateService mentalStateService = MentalStateService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSpace',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const NavManager(isGuest: false),
        '/guest': (context) => const NavManager(isGuest: true),
        '/chatbot': (context) => ChatBotScreen(),
      },
    );
  }
}