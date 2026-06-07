import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_globals.dart';
import '../constants/routes.dart';

class CallSignalingService {
  CallSignalingService._private();
  static final CallSignalingService instance = CallSignalingService._private();

  Timer? _pollTimer;
  String? _lastSeenCallId;

  void start() {
    // Poll every 3 seconds for new calls targeting this user
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollForCalls(),
    );
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollForCalls() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      // Query calls where callee_id == current user and status == 'ringing'
      final resp = await Supabase.instance.client
          .from('calls')
          .select()
          .eq('callee_id', user.id)
          .eq('status', 'ringing')
          .order('started_at', ascending: false)
          .limit(1);

      final data = resp as List<dynamic>?;
      if (data == null || data.isEmpty) return;
      final call = data.first as Map<String, dynamic>;
      final callId = call['id']?.toString();
      if (callId == null) return;
      if (_lastSeenCallId == callId) return; // already shown
      _lastSeenCallId = callId;

      // Show incoming call screen using navigator key
      final callerId = call['caller_id']?.toString();
      String callerName = 'Caller';

      String callerRole = '';
      String? callerAvatarUrl;
      if (callerId != null) {
        try {
          final caller = await Supabase.instance.client
              .from('users')
              .select('full_name, role, avatar_url')
              .eq('id', callerId)
              .maybeSingle();
          final callerMap = caller as Map<String, dynamic>?;
          callerName = callerMap?['full_name'] as String? ?? callerName;
          callerRole = callerMap?['role'] as String? ?? '';
          callerAvatarUrl = callerMap?['avatar_url'] as String?;
        } catch (_) {}
      }

      final channel =
          call['channel_name'] as String? ?? call['chat_id']?.toString() ?? '';

      if (appNavigatorKey.currentState == null) return;

      appNavigatorKey.currentState!.pushNamed(
        AppRoutes.incomingCall,
        arguments: {
          'callerName': callerName,
          'callerRole': callerRole,
          'avatarUrl': callerAvatarUrl,
          'channel': channel,
          'chatId': call['chat_id'],
          'callId': callId,
          'callerId': callerId,
          'callType': (call['call_type'] as String?) ?? 'audio',
        },
      );
    } catch (_) {
      // ignore polling errors
    }
  }
}
