import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SwapService {
  /// Your PC's local Wi-Fi IP. Update if your IP changes.
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.10.3:8000';
    }
    if (Platform.isIOS) {
      return 'http://192.168.10.3:8000';
    }
    return 'http://127.0.0.1:8000';

  }

  // ─── Recommendations ────────────────────────────────────────────────────────

  /// Fetches AI-recommended profiles for the current user.
  /// Includes profile picture URLs in the response.
  static Future<List<Map<String, dynamic>>> getRecommendations({
    double? lat,
    double? lng,
    String? filterType = "Meet",
    List<String>? roles,
    double? maxDist,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('SwapService: No user logged in.');
      }

      String urlStr = '$baseUrl/swap/recommendations?user_id=${user.id}';
      if (lat != null && lng != null) {
        urlStr += '&lat=$lat&lng=$lng';
      }
      if (filterType != null) {
        urlStr += '&filter_type=$filterType';
      }
      if (roles != null && roles.isNotEmpty) {
        for (var role in roles) {
          urlStr += '&roles=$role';
        }
      }
      if (maxDist != null) {
        urlStr += '&max_dist=$maxDist';
      }

      final url = Uri.parse(urlStr);
      print('SwapService: Requesting $url');

      final response = await http.get(url).timeout(const Duration(seconds: 45));

      print('SwapService: Status ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('SwapService: Response Data: $data'); // Log the response data
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          'Backend Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('SwapService Error: $e');
      rethrow;
    }
  }

  /// Fetches counts for filter pills (Meet, Waves, Views, Newbies)
  static Future<Map<String, dynamic>> getCounts() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {};

      final url = Uri.parse('$baseUrl/swap/counts?user_id=${user.id}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('SwapService counts error: $e');
      return {};
    }
  }

  // ─── Swipe Action ────────────────────────────────────────────────────────────

  /// Records a swipe action — action must be 'like', 'reject', or 'restore'.
  /// Returns a map with keys: status, is_match, message.
  static Future<Map<String, dynamic>> swipeUser(
    String targetUserId, {
    required String action, // 'like', 'reject', or 'restore'
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return {'status': 'error', 'is_match': false};
      }

      final url = Uri.parse('$baseUrl/swap/swipe');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': user.id,
              'target_user_id': targetUserId,
              'action': action,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      print('SwapService swipe error: ${response.statusCode} ${response.body}');
      return {'status': 'error', 'is_match': false};
    } catch (e) {
      print('SwapService swipeUser Error: $e');
      return {'status': 'error', 'is_match': false};
    }
  }

  /// Convenience wrapper — records a "like" swipe.
  static Future<Map<String, dynamic>> likeUser(String targetUserId) {
    return swipeUser(targetUserId, action: 'like');
  }

  /// Convenience wrapper — records a "reject" swipe.
  static Future<Map<String, dynamic>> rejectUser(String targetUserId) {
    return swipeUser(targetUserId, action: 'reject');
  }

  /// Convenience wrapper — records a "restore" swipe.
  static Future<Map<String, dynamic>> restoreUser(String targetUserId) {
    return swipeUser(targetUserId, action: 'restore');
  }

  // ─── Location Update ─────────────────────────────────────────────────────────

  /// Saves the user's current latitude/longitude to Supabase so
  /// the backend haversine calculation uses fresh data.
  static Future<void> updateUserLocation(double lat, double lng) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'latitude': lat, 'longitude': lng})
          .eq('id', user.id);
    } catch (e) {
      print('SwapService: Error updating location: $e');
    }
  }

  /// Fetches events created by a specific user for the 'Posts' tab
  static Future<List<Map<String, dynamic>>> getUserEvents(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .eq('creator_id', userId)
          .eq(
            'status_id',
            2,
          ) // Changed from 'approved' (string) to 2 (integer/smallint)
          .order('event_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('SwapService: Error fetching user events: $e');
      return [];
    }
  }

  /// Saves a profile to bookmarks/saved list
  static Future<bool> recordProfileView(String targetUserId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final url = Uri.parse('$baseUrl/swap/view');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'viewer_id': user.id, 'target_id': targetUserId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('SwapService: Error recording view: $e');
      return false;
    }
  }

  static Future<bool> saveProfile(String targetUserId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      // We'll use swipe_actions with a "save" action if possible,
      // or check if there's a dedicated table. For now, using as a specific swipe type.
      await Supabase.instance.client.from('swipe_actions').upsert({
        'actor_id': user.id,
        'target_id': targetUserId,
        'action': 'like', // Map love to high-priority like for now
      }, onConflict: 'actor_id,target_id');

      return true;
    } catch (e) {
      print('SwapService: Error saving profile: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMatches() async {

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      final url = Uri.parse('$baseUrl/swap/matches?user_id=${user.id}');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      return [];
    } catch (e) {
      print('SwapService matches error: $e');
      return [];
    }
  }
}

