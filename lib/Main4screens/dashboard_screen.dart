import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:safespace/Backend/quote.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safespace/chatbot/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import the chatbot screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late bool isDayTime;
  Timer? _timer;
  String? username;

  @override
  void initState() {
    super.initState();
    isDayTime = _checkIsDayTime();
    _fetchUsername();

    // Automatically update background (day/night) every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final currentlyDay = now.hour >= 6 && now.hour < 18;
      if (currentlyDay != isDayTime) {
        setState(() {
          isDayTime = currentlyDay;
        });
      }
    });
  }

  // Checks whether it's currently daytime (6 AM - 6 PM)
  bool _checkIsDayTime() {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 18;
  }

  // Fetch the logged-in user's username from Firestore
  Future<void> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        username = doc.data()?['username'] ?? 'User';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('dd MMM yyyy').format(DateTime.now());
    final String backgroundImage = isDayTime
        ? 'assets/images/day_bg.jpg'
        : 'assets/images/night_bg.jpg';

    return Stack(
      children: [
        // Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Overlay gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar with avatar, date, notification
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/profile.jpg'),
                    ),
                    Text(
                      today,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      onPressed: () {
                        // Navigate to notifications or quotes screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuoteUploadScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Greeting Section
                Text(
                  'Hello ${username ?? "..."} 👋',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'We hope you are doing great today.',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 30),

                // Thought of the Day Card (static placeholder)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Thought of the day',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your Firebase quote will go here.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Chat Box — onTap to open chatbot
                GestureDetector(
                  onTap: () {
                    // ✅ Navigate to chatbot screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Hello, ',
                                style: TextStyle(color: Colors.black87, fontSize: 16),
                              ),
                              TextSpan(
                                text: '${username ?? "..."}!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Let\'s Chat 💬',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // AI Suggestions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'AI Suggestions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('See all', style: TextStyle(color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 16),

                // Suggestion Cards
                Column(
                  children: [
                    suggestionCard(
                      icon: Icons.visibility_off,
                      title: "Limit Exposure to Screens",
                      subtitle: "Control your snoring!",
                    ),
                    const SizedBox(height: 10),
                    suggestionCard(
                      icon: Icons.bed,
                      title: "Pillow Improvement",
                      subtitle: "Change your pillows",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Reusable card widget for suggestions
  static Widget suggestionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}

// Dummy Notification screen
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: const Center(child: Text("No new notifications.")),
    );
  }
}
