import 'package:flutter/material.dart';
import 'package:safespace/navmanager.dart';
import 'package:safespace/authentication/sign_up.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace/authentication/auth_gate.dart';
import 'package:safespace/authentication/login_page.dart';
import 'package:safespace/screens/chatbot.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cpuhivcyhvqayzgdvdaw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNwdWhpdmN5aHZxYXl6Z2R2ZGF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMzNDc4NDgsImV4cCI6MjA2ODkyMzg0OH0.dO22JLQjE7UeQHvQn6mojILNuWi_02MiZ9quz5v8pNk',
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
