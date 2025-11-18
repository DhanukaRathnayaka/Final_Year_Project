import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class Exercise {
  final String id;
  final String name;
  final String duration;
  final String category;
  final String? categoryImagePath;
  final String description;
  final List<ChatMessage> chatFlow;

  Exercise({
    required this.id,
    required this.name,
    required this.duration,
    required this.category,
    this.categoryImagePath,
    required this.description,
    required this.chatFlow,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['exercise_name'] ?? json['name'] ?? 'Untitled Exercise',
      duration: json['duration'] ?? '5 min',
      category: json['category_name'] ?? json['category'] ?? 'General',
      categoryImagePath: json['category_image_path'],
      description: json['exercise_description'] ?? json['description'] ?? '',
      chatFlow: _parseChatFlow(json['chat_flow']),
    );
  }

  static List<ChatMessage> _parseChatFlow(dynamic chatFlowData) {
    if (chatFlowData == null) return [];

    if (chatFlowData is String) {
      try {
        final decoded = jsonDecode(chatFlowData);
        if (decoded is List) {
          return decoded.map((item) => ChatMessage.fromJson(item)).toList();
        }
      } catch (e) {
        print('Error parsing chat flow: $e');
      }
    }

    if (chatFlowData is List) {
      return chatFlowData
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final List<String> options;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.options,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'] ?? '',
      isUser: json['isUser'] ?? json['is_user'] ?? false,
      options: List<String>.from(json['options'] ?? []),
    );
  }
}

class ExerciseCategory {
  final String id;
  final String name;
  final String imagePath;
  final List<Exercise> exercises;

  ExerciseCategory({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.exercises,
  });

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    return ExerciseCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Untitled',
      imagePath: json['image_path'] ?? json['imagePath'] ?? '',
      exercises: [],
    );
  }
}

class ExerciseService {
  static final String baseUrl = Config.apiBaseUrl;

  /// Fetch all exercise categories from backend
  static Future<List<ExerciseCategory>> fetchCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/exercises/categories'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ExerciseCategory.fromJson(item)).toList();
      } else {
        print('Failed to fetch categories. Status: ${response.statusCode}');
        return _getFallbackCategories();
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return _getFallbackCategories();
    }
  }

  /// Fetch exercises for a specific category
  static Future<List<Exercise>> fetchExercisesByCategory(
    String categoryId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/exercises/category/$categoryId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Exercise.fromJson(item)).toList();
      } else {
        print('Failed to fetch exercises. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  /// Fetch a single exercise with chat flow
  static Future<Exercise?> fetchExercise(String exerciseId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/exercises/$exerciseId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Exercise.fromJson(data);
      } else {
        print('Failed to fetch exercise. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching exercise: $e');
      return null;
    }
  }

  /// Log exercise completion to backend
  static Future<bool> logExerciseCompletion({
    required String userId,
    required String exerciseId,
    required int duration,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/exercises/complete'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'exercise_id': exerciseId,
              'duration_seconds': duration,
              'completed_at': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Exercise completion logged successfully');
        return true;
      } else {
        print('Failed to log completion. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error logging exercise completion: $e');
      return false;
    }
  }

  /// Get user's exercise statistics
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/exercises/user/$userId/stats'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'completed_today': 0,
          'total_duration': 0,
          'weekly_average': 0.0,
          'streak': 0,
        };
      }
    } catch (e) {
      print('Error fetching user stats: $e');
      return {
        'completed_today': 0,
        'total_duration': 0,
        'weekly_average': 0.0,
        'streak': 0,
      };
    }
  }

  /// Fallback categories if backend is unavailable
  static List<ExerciseCategory> _getFallbackCategories() {
    // Return empty list - categories should be fetched from backend
    return [];
  }
}
