import 'package:flutter/material.dart';
// notifications_page.dart

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('This is the notifications page')),
    );
  }
}
