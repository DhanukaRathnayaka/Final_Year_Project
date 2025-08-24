import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SuggestionService {
  final String _baseUrl =
      'http://localhost:8000'; // Use 10.0.2.2 for Android emulator to access localhost

  SuggestionService();

  /// Fetch AI suggestions for a user
  Future<Map<String, dynamic>> getSuggestions() async {
    try {
      // Retrieve user_id from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        print('User ID not found in SharedPreferences');
        return {"doctors": [], "entertainments": []};
      }

      print('Fetching suggestions for user: $userId'); // Debug log

      // Make GET request to the new endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/api/suggestions/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        // Decode and return JSON
        final data = json.decode(response.body);
        print('Parsed suggestions data: $data'); // Debug log
        return data;
      } else if (response.statusCode == 404) {
        // No suggestions found for user
        print('No suggestions found for user: $userId');
        return {"doctors": [], "entertainments": []};
      } else {
        // Handle other failures
        print(
          'Failed to load suggestions: ${response.statusCode} - ${response.body}',
        );
        return {"doctors": [], "entertainments": []};
      }
    } catch (e) {
      // Handle exception
      print('Exception in getSuggestions: $e'); // Debug log
      return {"doctors": [], "entertainments": []};
    }
  }
}
