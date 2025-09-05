import 'dart:async';
import 'dart:convert';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Response model for AI-generated suggestions
class SuggestionResponse {
  final String userId;
  final String conversationId;
  final List<String> suggestions;

  SuggestionResponse({
    required this.userId,
    required this.conversationId,
    required this.suggestions,
  });

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionResponse(
      userId: json['user_id'],
      conversationId: json['conversation_id'],
      suggestions: List<String>.from(json['suggestions']),
    );
  }
}

/// Service for handling AI suggestions and general recommendations
class SuggestionService {
  // Get base URL from config
  static String get _baseUrl => Config.apiBaseUrl;

  const SuggestionService();

  /// Fetch AI suggestions based on conversation
  Future<SuggestionResponse> fetchAISuggestions({
    required List<String> conversation,
    required String userId,
    required String conversationId,
  }) async {
    // Validate input
    if (conversation.isEmpty) {
      throw Exception('Conversation cannot be empty');
    }

    try {
      // Create request body
      final requestBody = jsonEncode({
        'messages': conversation,
        'user_id': userId,
        'conversation_id': conversationId,
      });

      // Make API request with timeout
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_suggestions'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out after 30 seconds'),
          );

      // Parse response
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body);
      } on FormatException {
        throw Exception('Invalid response format: unable to parse JSON');
      }

      if (response.statusCode == 200) {
        // Validate response format
        if (!jsonResponse.containsKey('suggestions')) {
          throw Exception('Invalid response format: missing suggestions');
        }

        final suggestions = List<String>.from(jsonResponse['suggestions']);
        if (suggestions.isEmpty) {
          throw Exception('No suggestions were generated');
        }

        return SuggestionResponse.fromJson(jsonResponse);
      }

      // Handle non-200 responses
      String errorMessage;
      try {
        errorMessage = jsonResponse['detail'] ?? response.body;
      } catch (e) {
        errorMessage = response.body;
      }
      throw Exception('Failed to generate suggestions: $errorMessage');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on FormatException {
      throw Exception('Error parsing response. Please try again.');
    } catch (e) {
      throw Exception('Error fetching suggestions: $e');
    }
  }

  /// Fetch general suggestions for a user
  Future<Map<String, dynamic>> getSuggestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('User ID not found in SharedPreferences');
        return {"doctors": [], "entertainments": []};
      }

      print('Fetching suggestions for user: $userId'); // Debug log

      final response = await http
          .get(
            Uri.parse('$_baseUrl/api/suggestions/$userId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timed out'),
          );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed suggestions data: $data'); // Debug log
        return data;
      }

      if (response.statusCode == 404) {
        print('No suggestions found for user: $userId');
        return {"doctors": [], "entertainments": []};
      }

      print(
        'Failed to load suggestions: ${response.statusCode} - ${response.body}',
      );
      return {"doctors": [], "entertainments": []};
    } catch (e) {
      print('Exception in getSuggestions: $e');
      return {"doctors": [], "entertainments": []};
    }
  }
}
