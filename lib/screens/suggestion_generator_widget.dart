import 'package:flutter/material.dart';
import 'package:safespace/services/suggestion_service.dart';
import 'package:safespace/screens/ai_suggestions_screen.dart';

class SuggestionGeneratorWidget extends StatelessWidget {
  final List<String> conversationMessages;
  final String userId;
  final String conversationId;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const SuggestionGeneratorWidget({
    Key? key,
    required this.conversationMessages,
    required this.userId,
    required this.conversationId,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  Future<void> generateAndShowSuggestions(BuildContext context) async {
    if (conversationMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No conversation messages to generate suggestions from.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Generating suggestions...'),
            ],
          ),
          duration: const Duration(seconds: 10),
          backgroundColor: const Color.fromARGB(255, 243, 135, 33),
        ),
      );

      final suggestionService = SuggestionService();
      final suggestions = await suggestionService.fetchAISuggestions(
        conversation: conversationMessages,
        userId: userId,
        conversationId: conversationId,
      );

      // Clear any existing snackbars
      ScaffoldMessenger.of(context).clearSnackBars();

      if (suggestions.suggestions.isEmpty) {
        throw Exception('No suggestions were generated');
      }

      // Navigate to suggestions screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AISuggestionsScreen(suggestions: suggestions.suggestions),
        ),
      );

      // Call success callback if provided
      onSuccess?.call();
    } catch (e) {
      // Clear any existing snackbars
      ScaffoldMessenger.of(context).clearSnackBars();

      String errorMessage = e.toString();
      if (errorMessage.contains('OpenAI API error')) {
        errorMessage =
            'Unable to generate suggestions at this time. Please try again later.';
      }

      _showErrorSnackBar(context, errorMessage);
      print('Error generating suggestions: $e');

      // Call error callback if provided
      onError?.call();
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't have a visual representation by default
    // It's meant to be used by calling generateAndShowSuggestions()
    return const SizedBox.shrink();
  }
}