import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/api_constants.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: ApiConstants.geminiApiKey,
    );
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String skillName) async {
    final prompt = '''
      Generate a technical multiple-choice quiz for the skill: "$skillName".
      Create exactly 10 questions.
      Each question must have:
      - "question": The question text.
      - "options": A list of 4 options.
      - "correctAnswer": The exact string of the correct option.
      
      The output must be a valid JSON list of objects. Do not include any markdown formatting like ```json ... ```. Just the raw JSON.
      Example structure:
      [
        {
          "question": "What is ...?",
          "options": ["A", "B", "C", "D"],
          "correctAnswer": "A"
        }
      ]
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        throw Exception('Empty response from Gemini');
      }

      String responseText = response.text!;
      // Clean up markdown if present
      responseText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();

      final List<dynamic> jsonList = jsonDecode(responseText);
      return List<Map<String, dynamic>>.from(jsonList);
    } catch (e) {
      throw Exception('Failed to generate quiz: $e');
    }
  }
}
