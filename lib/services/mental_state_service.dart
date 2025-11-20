import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class MentalStateService {
  // Use backend API endpoint instead of direct Groq API
  // This will automatically use the deployed backend if
  // --dart-define=USE_DEPLOYED_BACKEND=true is supplied during build.
  static String get _backendUrl => Config.apiBaseUrl;
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
    try {
      // Call backend prediction endpoint which uses Groq with fallback heuristic
      final response = await http.post(
        Uri.parse('$_backendUrl/api/predict-mental-state'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Backend Prediction Response:\n${jsonEncode(data)}');

        try {
          final prediction = data['prediction'];
          final confidence = data['confidence'];

          if (prediction == null || confidence == null) {
            throw FormatException('Missing prediction or confidence');
          }

          return {
            'prediction': prediction,
            'confidence': (confidence as num).toDouble(),
          };
        } catch (e) {
          print('Error parsing backend response: $e');
          return {'prediction': 'neutral/calm', 'confidence': 0.5};
        }
      } else {
        throw Exception('Backend API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Prediction error: $e');
      // Fallback to neutral if backend is unavailable
      return {'prediction': 'neutral/calm', 'confidence': 0.5};
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
