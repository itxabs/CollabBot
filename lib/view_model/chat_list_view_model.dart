import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/chat_model.dart';
import '../data/repositories/chat_repository.dart';
import '../data/services/chat_service.dart';
import '../local_db/local_message_db.dart';

class ChatListViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ChatRepository _chatRepository;
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  List<ChatSummary> chats = [];
  bool _disposed = false;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  final Set<String> _knownMessageIds = <String>{};
  bool _isRealtimePrimed = false;

  ChatListViewModel() {
    _chatRepository = ChatRepository(ChatService(_supabase));
    loadChats();
  }

  @override
  void dispose() {
    _disposed = true;
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<ChatSummary> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    final query = searchQuery.toLowerCase();
    return chats.where((chat) {
      return chat.otherUserName.toLowerCase().contains(query) ||
          (chat.lastMessage?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery = query;
    safeNotifyListeners();
  }

  Future<void> loadChats() async {
    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not logged in');
      }
      final currentUserId = currentUser.id;
      await _hydrateChats(currentUserId);
      _ensureRealtimeSubscription(currentUserId);
    } catch (e) {
      if (_disposed) return;
      errorMessage = 'Failed to load chats. ${e.toString()}';
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<void> deleteChat(String chatId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User is not logged in');
    }

    isLoading = true;
    errorMessage = null;
    safeNotifyListeners();

    try {
      await _chatRepository.leaveChat(chatId, currentUser.id);
      chats.removeWhere((chat) => chat.chatId == chatId);
    } catch (e) {
      if (_disposed) return;
      errorMessage = 'Failed to delete chat. ${e.toString()}';
      rethrow;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  Future<void> _hydrateChats(String currentUserId) async {
    final list = await _chatRepository.getUserChats(currentUserId);

    final enriched = <ChatSummary>[];
    for (final chat in list) {
      if (_disposed) return;
      final unread = await LocalMessageDb.instance.getUnreadCount(
        chat.chatId,
        currentUserId,
      );
      enriched.add(
        ChatSummary(
          chatId: chat.chatId,
          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
          otherUserAvatarUrl: chat.otherUserAvatarUrl,
          otherUserRole: chat.otherUserRole,
          lastMessage: chat.lastMessage,
          lastMessageAt: chat.lastMessageAt,
          hasUnread: unread > 0,
        ),
      );
    }

    chats = enriched;
  }

  void _ensureRealtimeSubscription(String currentUserId) {
    if (_messagesSubscription != null) return;

    _messagesSubscription = _chatRepository.subscribeToAllMessages().listen(
      (rows) async {
        if (_disposed) return;

        if (!_isRealtimePrimed) {
          for (final row in rows) {
            final id = row['id'] as String?;
            if (id != null) _knownMessageIds.add(id);
          }
          _isRealtimePrimed = true;
          return;
        }

        bool hasRelevantIncoming = false;
        for (final row in rows) {
          final messageId = row['id'] as String?;
          if (messageId == null || _knownMessageIds.contains(messageId)) {
            continue;
          }
          _knownMessageIds.add(messageId);

          final senderId = row['sender_id'] as String?;
          final chatId = row['chat_id'] as String?;
          if (senderId == null || chatId == null || senderId == currentUserId) {
            continue;
          }

          final belongsToCurrentUser = await _chatRepository.isParticipant(
            chatId,
            currentUserId,
          );
          if (!belongsToCurrentUser) continue;

          hasRelevantIncoming = true;
        }

        if (hasRelevantIncoming && !_disposed) {
          await _hydrateChats(currentUserId);
          safeNotifyListeners();
        }
      },
      onError: (e) {
        if (_disposed) return;
        errorMessage = 'Realtime chat updates failed: $e';
        safeNotifyListeners();
      },
    );
  }
}
