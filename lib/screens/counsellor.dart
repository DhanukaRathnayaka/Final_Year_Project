import 'package:flutter/material.dart';

class CounsellorScreen extends StatelessWidget {
  const CounsellorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counsellor')),
      body: const Center(child: Text('Counsellor screen content here')),
    );
  }
}
