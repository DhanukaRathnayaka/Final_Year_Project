import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Use IPv4 address instead of localhost for Android emulator compatibility
  static const String _baseUrl = 'http://localhost:8000/api/chat';

  static Future<String> sendMessage(
    String userMessage,
    String model, {
    String? userId,
  }) async {
    final url = Uri.parse(_baseUrl);

    final payload = {
      "message": userMessage,
      "model": model,
      if (userId != null) "user_id": userId,
    };

    print('📤 Sending chat request:');
    print('URL: $_baseUrl');
    print('Payload: $payload');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(payload),
      );

      print('📥 Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Response data: $data');

          final aiResponse = data['response'];
          if (aiResponse == null) {
            print('❌ No response field in data');
            return "⚠ Invalid response format from server";
          }

          print('✅ AI Response: $aiResponse');
          return aiResponse;
        } catch (e) {
          print('❌ JSON decode error: $e');
          print('Raw response: ${response.body}');
          return "⚠ Error processing server response";
        }
      } else {
        print("❌ Server Error Status: ${response.statusCode}");
        print("Server Error Body: ${response.body}");
        return "⚠ Server Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      print("❌ Network Error: $e");
      return "⚠ Network Error: $e";
    }
  }
}
