import 'package:flutter/material.dart';
import 'package:safespace/navmanager.dart';



void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSpace',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NavManager(), // This manages all navigation
      debugShowCheckedModeBanner: false,
    );
  }
}