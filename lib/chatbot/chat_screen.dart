import 'package:flutter/material.dart';
import 'package:safespace/chatbot/chat_bubble.dart';
import 'package:safespace/chatbot/message_input.dart';





class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> messages = [];

  void _sendMessage(String text) {
    setState(() {
      messages.add({'role': 'user', 'text': text});
    });

    // TODO: Call backend and add AI response
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mental Health Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (ctx, index) {
                final msg = messages[index];
                return ChatBubble(
                  message: msg['text']!,
                  isUser: msg['role'] == 'user',
                );
              },
            ),
          ),
          MessageInput(onSend: _sendMessage),
        ],
      ),
    );
  }
}
