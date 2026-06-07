import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/routes.dart';

class CallHelper {
  static String get baseUrl {
    if (  Platform.isAndroid || Platform.isIOS) {
      return 'http://192.168.100.8:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static int _agoraUidForUser(String userId) {
    final compact = userId.replaceAll('-', '');
    final seed = int.tryParse(compact.substring(0, 8), radix: 16) ?? userId.hashCode;
    return (seed.abs() % 2147483646) + 1;
  }

  static Future<void> startCall(
    BuildContext context,
    String chatId,
    String callerName,
    String? callerRole,
    String? calleeUserId,
    bool enableVideo,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in to start a call')));
      return;
    }

    final uri = Uri.parse('$baseUrl/agora/token');
    final agoraUid = _agoraUidForUser(currentUser.id);
    final payload = jsonEncode({'chat_id': chatId, 'user_id': currentUser.id, 'uid': agoraUid});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 15));
      Navigator.of(context).pop();
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final appId = data['appId'] as String;
        final token = data['token'] as String;
        final channel = data['channel'] as String;
        final uid = data['uid'] as int? ?? 0;

        // Record call signaling row for the callee (so they get notified)
        try {
          if (calleeUserId == null || calleeUserId.isEmpty) {
            throw Exception('Missing callee user id');
          }

          final entry = {
            'chat_id': chatId,
            'caller_id': currentUser.id,
            'callee_id': calleeUserId,
            'channel_name': channel,
            'status': 'ringing',
            'call_type': enableVideo ? 'video' : 'audio',
          };
          final callRow = await Supabase.instance.client
              .from('calls')
              .insert(entry)
              .select('id')
              .single();
          final callId = (callRow as Map<String, dynamic>)['id']?.toString();
          if (callId == null || callId.isEmpty) {
            throw Exception('Call row was created without an id');
          }

          // Try fetching the other participant's avatar so the active call/end screen shows the remote user.
          String? otherAvatar;
          String callerRoleLocal = callerRole ?? '';
          if (calleeUserId != null && calleeUserId.isNotEmpty) {
            try {
              final other = await Supabase.instance.client
                  .from('users')
                  .select('avatar_url, role')
                  .eq('id', calleeUserId)
                  .maybeSingle();
              final otherMap = other as Map<String, dynamic>?;
              otherAvatar = otherMap?['avatar_url'] as String?;
              callerRoleLocal = otherMap?['role'] as String? ?? callerRoleLocal;
            } catch (_) {}
          }

          Navigator.of(context).pushNamed(
            AppRoutes.activeCall,
            arguments: {
              'appId': appId,
              'token': token,
              'channel': channel,
              'uid': uid,
              'enableVideo': enableVideo,
              'callerName': callerName,
              'callerRole': callerRoleLocal,
              'avatarUrl': otherAvatar,
              'chatId': chatId,
              'otherUserId': calleeUserId,
              'callId': callId,
            },
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not notify receiver: $e')));
          return;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start call: ${resp.statusCode} ${resp.body}')));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start call: $e')));
    }
  }

  static Future<void> answerCall(
    BuildContext context,
    String chatId,
    String callId,
    String? callType, {
    String callerName = 'Caller',
    String? avatarUrl,
    String? otherUserId,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    final uri = Uri.parse('$baseUrl/agora/token');
    final agoraUid = _agoraUidForUser(currentUser.id);
    final payload = jsonEncode({'chat_id': chatId, 'user_id': currentUser.id, 'uid': agoraUid});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: payload).timeout(const Duration(seconds: 15));
      Navigator.of(context).pop();
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final appId = data['appId'] as String;
        final token = data['token'] as String;
        final channel = data['channel'] as String;
        final uid = data['uid'] as int? ?? 0;

        // Update call status to ongoing
        try {
          await Supabase.instance.client.from('calls').update({'status': 'ongoing'}).eq('id', callId);
        } catch (_) {}
        final enableVideo = (callType ?? 'audio') == 'video';

        Navigator.of(context).pushReplacementNamed(
          AppRoutes.activeCall,
          arguments: {
            'appId': appId,
            'token': token,
            'channel': channel,
            'uid': uid,
            'enableVideo': enableVideo,
            'callerName': callerName,
            'callerRole': '',
            'avatarUrl': avatarUrl,
            'chatId': chatId,
            'otherUserId': otherUserId,
            'callId': callId,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get token: ${resp.statusCode} ${resp.body}')));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get token: $e')));
    }
  }

  static Future<void> declineCall(String callId) async {
    try {
      await Supabase.instance.client.from('calls').update({'status': 'rejected'}).eq('id', callId);
    } catch (_) {}
  }

  static Future<void> endCall(String callId) async {
    try {
      await Supabase.instance.client
          .from('calls')
          .update({'status': 'ended', 'ended_at': DateTime.now().toIso8601String()})
          .eq('id', callId);
    } catch (_) {}
  }
}
