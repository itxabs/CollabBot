import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/chat_presence_service.dart';
import '../core/services/notification_service.dart';
import '../data/repositories/chat_repository.dart';
import '../data/services/chat_service.dart';

class MessageNotificationViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ChatRepository _chatRepository;

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  final Set<String> _knownMessageIds = <String>{};
  final Map<String, String> _senderNameCache = <String, String>{};
  bool _isRealtimePrimed = false;
  String? _currentUserId;

  MessageNotificationViewModel() {
    _chatRepository = ChatRepository(ChatService(_supabase));
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      _startMessagesListener();
    }
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((authState) {
      final nextUserId = authState.session?.user.id;
      if (nextUserId == _currentUserId) return;

      _currentUserId = nextUserId;
      _messagesSubscription?.cancel();
      _messagesSubscription = null;
      _knownMessageIds.clear();
      _senderNameCache.clear();
      _isRealtimePrimed = false;

      if (_currentUserId != null) {
        _startMessagesListener();
      }
    });
  }

  void _startMessagesListener() {
    final userId = _currentUserId;
    if (userId == null || _messagesSubscription != null) return;

    _messagesSubscription = _chatRepository.subscribeToAllMessages().listen((
      rows,
    ) async {
      if (_currentUserId == null) return;

      if (!_isRealtimePrimed) {
        for (final row in rows) {
          final id = row['id'] as String?;
          if (id != null) _knownMessageIds.add(id);
        }
        _isRealtimePrimed = true;
        return;
      }

      for (final row in rows) {
        final messageId = row['id'] as String?;
        if (messageId == null || _knownMessageIds.contains(messageId)) {
          continue;
        }
        _knownMessageIds.add(messageId);

        final senderId = row['sender_id'] as String?;
        final chatId = row['chat_id'] as String?;
        if (senderId == null || chatId == null || senderId == _currentUserId) {
          continue;
        }

        final belongsToCurrentUser = await _chatRepository.isParticipant(
          chatId,
          _currentUserId!,
        );
        if (!belongsToCurrentUser) continue;

        final isActiveChat = ChatPresenceService.instance.activeChatId == chatId;
        if (isActiveChat) continue;

        final senderName = await _resolveSenderName(senderId);
        final messageText = _normalizeMessageText(row['content'] as String? ?? '');
        await NotificationService.instance.notifyIncomingMessage(
          senderName: senderName,
          messageText: messageText,
          showInAppBanner: true,
        );
      }
    });
  }

  Future<String> _resolveSenderName(String senderId) async {
    final cached = _senderNameCache[senderId];
    if (cached != null) return cached;
    final fetched = await _chatRepository.getUserNameById(senderId);
    _senderNameCache[senderId] = fetched;
    return fetched;
  }

  String _normalizeMessageText(String rawContent) {
    if (rawContent.startsWith('[LOC:')) {
      final endBracket = rawContent.indexOf(']');
      if (endBracket > 5 && endBracket < rawContent.length - 1) {
        return rawContent.substring(endBracket + 1).trim();
      }
      return 'Shared location';
    }

    final trimmed = rawContent.trim();
    if (trimmed.isEmpty) return 'New message';
    return trimmed;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
