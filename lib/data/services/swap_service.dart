import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SwapService {
  // Update to use the correct current local IP: 192.168.10.6
  static String get baseUrl {
    // 10.0.2.2 is the special alias for Android Emulators to reach host localhost
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    // For iOS simulator or physical devices on the same Wi-Fi
    if (Platform.isIOS) {
      return 'http://192.168.10.6:8000';
    }
    return 'http://127.0.0.1:8000';
  }
  
  /// Fetches AI recommended profiles for the current user
  static Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      // If we don't have a user, return mock data for development
      if (user == null) {
        print("SwapService: No user logged in, returning mock data for testing.");
        return _getMockData();
      }

      final url = Uri.parse('$baseUrl/swap/recommendations?user_id=${user.id}');
      
      // Add a timeout to prevent hanging forever
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('SwapService: Backend returned errors \${response.statusCode}. Falling back to mock data.');
        return _getMockData();
      }
    } catch (e) {
      print('SwapService Error: $e. Falling back to mock data.');
      // Return mock data so the UI doesn't hang in dev
      return _getMockData();
    }
  }

  /// Records a like constraint
  static Future<Map<String, dynamic>> likeUser(String likedUserId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {'status': 'error', 'is_match': false};

      final url = Uri.parse('$baseUrl/swap/like');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.id,
          'liked_user_id': likedUserId,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': 'error', 'is_match': false};
    } catch (e) {
      print('SwapService Like Error: $e');
      return {'status': 'error', 'is_match': false};
    }
  }

  /// Mock data for development and testing
  static List<Map<String, dynamic>> _getMockData() {
    return [
      {
        "user_id": "1",
        "name": "Sarah Ahmed",
        "title": "Senior Student",
        "degree": "BSSE - 7th Semester",
        "description": "I'm a final-year Software Engineering student interested in Flutter development and UI/UX design. Looking for collaborators for my FYP project.",
        "skills": ["Flutter", "Firebase", "Dart", "UI/UX Design"],
        "rating": "4.8",
        "distance": "2.3 km",
        "initials": "SA",
        "mentorships": 15,
      },
      {
        "user_id": "2",
        "name": "Fahad Khan",
        "title": "Full Stack Dev",
        "degree": "BSCS - 6th Semester",
        "description": "Expert in Node.js and React. Currently learning Flutter and looking to mentor juniors or collaborate on open-source projects.",
        "skills": ["Node.js", "React", "MongoDB", "Python"],
        "rating": "4.5",
        "distance": "5.1 km",
        "initials": "FK",
        "mentorships": 8,
      },
      {
        "user_id": "3",
        "name": "Amber Khalid",
        "title": "Data Scientist",
        "degree": "MSCS - 1st Semester",
        "description": "Focusing on Machine Learning and Data Visualization. Interested in using AI to solve real-world problems.",
        "skills": ["Python", "TensorFlow", "Pandas", "Scikit-Learn"],
        "rating": "4.9",
        "distance": "1.2 km",
        "initials": "AK",
        "mentorships": 22,
      },
    ];
  }
}

