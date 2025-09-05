import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MentalStateService {
  // TODO: Move API key to environment variables or secure configuration
  // This should be loaded from a secure source, not hardcoded
  static const String _groqApiKey = String.fromEnvironment('GROQ_API_KEY',
    defaultValue: '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');
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> mentalConditions = [
    "happy/positive",
    "stressed/anxious",
    "depressed/sad",
    "angry/frustrated",
    "neutral/calm",
    "confused/uncertain",
    "excited/energetic"
  ];

  Future<Map<String, dynamic>> predict(String message) async {
    final prompt = """
    Analyze the following message and classify the writer's mental state.
    Only respond with ONE of these exact conditions: Do not take greetings to analyse.
    ${mentalConditions.join(", ")}
    
    Message: "$message"
    
    Also provide a confidence score between 0.7 and 1.0.
    
    Return your response in this exact JSON format:
    {
        "prediction": "selected_condition",
        "confidence": 0.85
    }
    """;

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-70b-8192',  // Updated to match chatbot model
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 100,
          'response_format': {'type': 'json_object'}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = jsonDecode(data['choices'][0]['message']['content']);
        return {
          'prediction': result['prediction'],
          'confidence': result['confidence'].toDouble()
        };
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Prediction error: $e');
      return {'prediction': 'neutral/calm', 'confidence': 0.7};
    }
  }

  Future<void> analyzeUserMentalState(String userId) async {
    try {
      // Get user messages from Supabase
      final messages = await _supabase
          .from('messages')
          .select()
          .eq('user_id', userId);
      
      if (messages.isEmpty) {
        print('No messages found for user $userId');
        return;
      }

      final stateCounts = <String, int>{};
      var confidenceSum = 0.0;
      final recentMessages = messages.length > 20 
          ? messages.sublist(messages.length - 20) 
          : messages;

      // Analyze individual messages
      for (final msg in recentMessages) {
        final result = await predict(msg['message']);
        stateCounts.update(
          result['prediction'], 
          (value) => value + 1, 
          ifAbsent: () => 1
        );
        confidenceSum += result['confidence'];
      }

      final totalMessages = recentMessages.length;
      final dominantStateEntry = stateCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      final avgConfidence = confidenceSum / totalMessages;

      final dominantState = dominantStateEntry.value / totalMessages < 0.4
          ? 'mixed/no_clear_pattern'
          : dominantStateEntry.key;

      // Save report to Supabase
      await _supabase
          .from('mental_state_reports')
          .insert({
            'user_id': userId,
            'report': jsonEncode({
              'user_id': userId,
              'total_messages_analyzed': totalMessages,
              'dominant_state': dominantState,
              'confidence': avgConfidence,
              'state_distribution': stateCounts,
            }),
            'dominant_state': dominantState,
            'confidence': avgConfidence,
            'created_at': DateTime.now().toIso8601String(),
          });

      print('✅ Mental state analysis completed for user $userId');

    } catch (e) {
      print('Error in mental state analysis: $e');
    }
  }

  // Check if user has enough messages to analyze
  Future<bool> hasEnoughMessages(String userId) async {
    try {
      final messages = await _supabase
          .from('messages')
          .select()
          .eq('user_id', userId);

      return messages.length >= 5; // Minimum 5 messages
    } catch (e) {
      return false;
    }
  }
}