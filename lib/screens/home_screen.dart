import 'package:flutter/material.dart';

// Entry point of the application
void main() {
  runApp(const SafeSpaceApp());
}

// Main application widget
class SafeSpaceApp extends StatelessWidget {
  const SafeSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// Home screen widget containing UI elements
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome text
              Text(
                'Welcome back, Sarina!',
                style: TextStyle(
                  // fontFamily: 'Alegreya',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontStyle: FontStyle.italic, // Italic style for variable font
                ),
              ),
              const SizedBox(height: 10),
              // Mood selection prompt
              const Text('How are you feeling today?'),
              const SizedBox(height: 10),
              // Mood selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _moodButton('Happy', Icons.sentiment_satisfied, Colors.pink),
                  _moodButton('Calm', Icons.nightlight_round, Colors.purple),
                  _moodButton('Relax', Icons.spa, Colors.orange),
                  _moodButton('Focus', Icons.self_improvement, Colors.teal),
                ],
              ),
              const SizedBox(height: 20),
              // Motivational message
              const Text(
                'You are stronger than you think. Take a deep breath you’ve got this! 😊',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _chatBubble(),
              const SizedBox(height: 20),
              // Task section header
              const Text("Today's Task",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // List of tasks
              Expanded(
                child: ListView(
                  children: [
                    _taskCard(
                        'Peer Group Meetup',
                        'Let’s open up to the thing that matters among the people',
                        Icons.people,
                        Colors.pink.shade100),
                    _taskCard(
                        'Listen to some music',
                        'Heal your mind with our stunning healing tracks and songs',
                        Icons.music_note,
                        Colors.orange.shade100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for mood selection buttons
  Widget _moodButton(String text, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontSize: 12))
      ],
    );
  }

  // Widget for chat bubble section
  Widget _chatBubble() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text('Hello, Sarina!\nLet’s Chat',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.spa, color: Colors.blue, size: 40),
      ],
    );
  }

  // Widget for task cards
  Widget _taskCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: Colors.pink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(description, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 5),
                Text('Join Now →',
                    style: TextStyle(
                        color: Colors.pink.shade700,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
