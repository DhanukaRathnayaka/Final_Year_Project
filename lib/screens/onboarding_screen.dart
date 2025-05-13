import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safespace/Authentication/welcome_screen.dart';

class ChatOnboardingScreen extends StatefulWidget {
  const ChatOnboardingScreen({super.key});

  @override
  State<ChatOnboardingScreen> createState() => _ChatOnboardingScreenState();
}

class _ChatOnboardingScreenState extends State<ChatOnboardingScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chat = [];
  int _step = 0;

  final List<String> _botQuestions = [
    "Hi! Welcome to SafeSpace 👋",
    "We care about your mental wellbeing ❤️",
    "Are you here to relax, learn, or just explore?",
    "Great! You'll find music, support, and tools here.",
    "Shall we begin your journey?"
  ];

  void _sendMessage(String userMessage) {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _chat.add({'sender': 'user', 'text': userMessage});
    });

    _controller.clear();

    // Add next bot response after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_step < _botQuestions.length) {
        setState(() {
          _chat.add({'sender': 'bot', 'text': _botQuestions[_step]});
          _step++;
        });
      }
    });
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()), // Navigate to WelcomeScreen
    );
  }

  @override
  void initState() {
    super.initState();
    // Start with first bot message
    _chat.add({'sender': 'bot', 'text': _botQuestions[_step]});
    _step++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Let's Get Started")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _chat.length,
              itemBuilder: (context, index) {
                final message = _chat[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_step < _botQuestions.length) // Show input only if there are questions left
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Type your response...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            )
          else // End of flow, show finish button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton(
                onPressed: _finishOnboarding,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: const Text("Finish Onboarding"),
              ),
            ),
        ],
      ),
    );
  }
}
