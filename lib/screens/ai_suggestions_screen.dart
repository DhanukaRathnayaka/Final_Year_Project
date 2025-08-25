import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

class AISuggestionsScreen extends StatelessWidget {
  final List<String> suggestions;

  const AISuggestionsScreen({Key? key, required this.suggestions})
    : super(key: key);

  // Helper method to pick an appropriate icon based on suggestion content
  IconData _getIconForSuggestion(String suggestion) {
    suggestion = suggestion.toLowerCase();
    if (suggestion.contains('break') || suggestion.contains('stretch'))
      return LineIcons.walking;
    if (suggestion.contains('write') || suggestion.contains('journal'))
      return LineIcons.book;
    if (suggestion.contains('music') || suggestion.contains('listen'))
      return LineIcons.music;
    if (suggestion.contains('breath')) return LineIcons.wind;
    if (suggestion.contains('water') || suggestion.contains('drink'))
      return LineIcons.glassWhiskey;
    if (suggestion.contains('walk')) return LineIcons.running;
    if (suggestion.contains('meditate')) return LineIcons.peace;
    if (suggestion.contains('talk') || suggestion.contains('friend'))
      return LineIcons.users;
    return LineIcons.lightbulb; // default icon
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/day_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.white,
                    ),
                    const Text(
                      'AI Suggestions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Based on our conversation, here are some suggestions:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = suggestions[index];
                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getIconForSuggestion(suggestion),
                                      color: Colors.blue,
                                      size: 28,
                                    ),
                                  ),
                                  title: Text(
                                    suggestion,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
