import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/chat_model.dart';
import '../data/services/chat_service.dart';
import '../local_db/local_message_db.dart';

class ChatListViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final ChatService _chatService;
  bool isLoading = false;
  String? errorMessage;
  String searchQuery = '';
  List<ChatSummary> chats = [];
  bool _disposed = false;

  ChatListViewModel() {
    _chatService = ChatService(_supabase);
    loadChats();
  }

  @override
  void dispose() {
    _disposed = true;
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
      final list = await _chatService.getUserChats(currentUserId);

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
            lastMessage: chat.lastMessage,
            lastMessageAt: chat.lastMessageAt,
            hasUnread: unread > 0,
          ),
        );
      }

      chats = enriched;
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
      await _chatService.leaveChat(chatId, currentUser.id);
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
}
