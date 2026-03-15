import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SwapService {
  // Using localhost for Android emulator. For iOS simulator, use localhost.
  // For physical devices, use the computer's actual IP address.
  static String get baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://192.168.100.8:8000';
    }
    return 'http://127.0.0.1:8000';
  }
  
  /// Fetches AI recommended profiles for the current user
  static Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$baseUrl/swap/recommendations?user_id=${user.id}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load recommendations: \${response.statusCode}');
      }
    } catch (e) {
      print('SwapService Error: $e');
      // For immediate testing without a real Supabase Auth session, 
      // you could return a hardcoded test request here instead of throwing.
      rethrow;
    }
  }

  /// Records a like constraint
  static Future<bool> likeUser(String likedUserId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final url = Uri.parse('$baseUrl/swap/like');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.id,
          'liked_user_id': likedUserId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('SwapService Like Error: \$e');
      return false;
    }
  }
}
