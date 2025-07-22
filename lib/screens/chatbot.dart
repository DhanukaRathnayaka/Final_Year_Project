import 'package:flutter/material.dart';
import 'package:safespace/services/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


class ChatBotScreen extends StatefulWidget {
  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  String selectedModel = "Mistral AI"; // Fixed model

  void handleSend() async {
    String userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": userInput});
      _controller.clear();
      isLoading = true;
    });

    // Add a temporary "thinking..." message
    messages.add({"sender": "bot", "text": "Thinking..."});
    setState(() {});

    String botReply = await ChatService.sendMessage(userInput, selectedModel);

    // Remove the "Thinking..." placeholder
    messages.removeLast();

    setState(() {
      messages.add({"sender": "bot", "text": botReply});
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8F7),
      appBar: AppBar(
        backgroundColor: Color(0xFFB2DFDB),
        title: Row(
          children: [
            Icon(Icons.spa, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "SafeSpace Chat",
              style: TextStyle(fontFamily: 'Arial Rounded', fontSize: 20),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(14),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Color(0xFF80CBC4) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade300,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: MarkdownBody(
                      data: msg['text'] ?? '',
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: "Type something to share...",
                      filled: true,
                      fillColor: Color(0xFFE0F2F1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF26A69A),
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
