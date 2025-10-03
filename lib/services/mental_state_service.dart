import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class MentalStateService {
  // TODO: Move API key to environment variables or secure configuration
  // This should be loaded from a secure source, not hardcoded
  static const String _groqApiKey =
      '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';
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> mentalConditions = [
    "happy/positive",
    "stressed/anxious",
    "depressed/sad",
    "angry/frustrated",
    "neutral/calm",
    "confused/uncertain",
    "excited/energetic",
  ];

  Future<Map<String, dynamic>> predict(String message) async {
    final prompt =
        """
    You are an expert mental health analyst. Analyze the following message and classify the writer's emotional/mental state.

    CRITICAL INSTRUCTION: DO NOT DEFAULT TO NEUTRAL/CALM UNLESS THERE IS GENUINELY NO EMOTIONAL CONTENT.

    IMPORTANT GUIDELINES:
    1. Analyze ALL messages, including short ones, greetings, and single words
    2. Even brief messages like "hi", "ok", "no" can convey emotional tone
    3. Look for subtle emotional indicators in tone, punctuation, and word choice
    4. Consider context clues like exclamation marks, question marks, capitalization
    5. Every message has some emotional undertone - find it
    6. BE BOLD in your classifications - avoid the safe "neutral/calm" option

    CLASSIFICATION OPTIONS (choose exactly one):
    ${mentalConditions.join(", ")}

    ANALYSIS GUIDELINES:
    - "happy/positive": Joy, satisfaction, optimism, gratitude, excitement, enthusiastic greetings
    - "stressed/anxious": Worry, pressure, nervousness, overwhelm, uncertain questions
    - "depressed/sad": Sadness, hopelessness, emptiness, grief, flat/monotone responses
    - "angry/frustrated": Anger, irritation, rage, resentment, short/abrupt responses
    - "neutral/calm": ONLY for genuinely balanced, peaceful, matter-of-fact content
    - "confused/uncertain": Doubt, bewilderment, indecision, questioning tone, hesitation
    - "excited/energetic": High energy, enthusiasm, anticipation, exclamation marks, caps

    PUNCTUATION ANALYSIS:
    - "!" → excited/energetic or angry/frustrated
    - "?" → confused/uncertain
    - "..." → depressed/sad or confused/uncertain
    - ALL CAPS → angry/frustrated or excited/energetic

    Message: "$message"

    Provide confidence score between 0.7 and 1.0. Even for short messages, provide confident analysis.

    Return your response in this exact JSON format:
    {
        "prediction": "exact_condition_from_list",
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
          'model': 'llama-3.1-8b-instant', // Updated to use instant model
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 100,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          '📊 Raw Groq API Response:\n${data['choices'][0]['message']['content']}',
        );

        try {
          final result = jsonDecode(data['choices'][0]['message']['content']);
          if (!result.containsKey('prediction') ||
              !result.containsKey('confidence')) {
            throw FormatException('Invalid response format');
          }
          return {
            'prediction': result['prediction'],
            'confidence': result['confidence'].toDouble(),
          };
        } catch (e) {
          print('Error parsing Groq response: $e');
          return {'prediction': 'confused/uncertain', 'confidence': 0.7};
        }
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Prediction error: $e');
      return {'prediction': 'confused/uncertain', 'confidence': 0.7};
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
      for (var i = 0; i < recentMessages.length; i++) {
        final msg = recentMessages[i];
        final result = await predict(msg['message']);
        stateCounts.update(
          result['prediction'],
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        confidenceSum += result['confidence'];
        print(
          'Message ${i + 1}: ${result['prediction']} (confidence: ${result['confidence'].toStringAsFixed(2)})',
        );
      }

      final totalMessages = recentMessages.length;
      final dominantStateEntry = stateCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      final avgConfidence = confidenceSum / totalMessages;

      final dominantState = dominantStateEntry.value / totalMessages < 0.25
          ? 'mixed/no_clear_pattern'
          : dominantStateEntry.key;

      // Save report to Supabase
      await _supabase.from('mental_state_reports').insert({
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
