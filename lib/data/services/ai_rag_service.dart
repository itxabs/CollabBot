import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiRagService {
  // Matching the base URL used in ResumeAnalyzerViewModel
  String get _baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://192.168.100.8:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Combined call to the Python Backend to get an AI-powered suggested response
  Future<String> generateAiResponse(String incomingMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/suggest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': incomingMessage}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['suggestion'] ?? "I'm sorry, I couldn't generate a response.";
      } else {
        print('Backend Error (${response.statusCode}): ${response.body}');
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Python AI Backend: $e');
      // Gentle fallback to ensure UI doesn't break
      return "I'm having trouble connecting to my AI brain right now. Please try again later.";
    }
  }
}



