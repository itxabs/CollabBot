import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

class ChatService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  ChatService(this._supabase);

  Future<List<ChatSummary>> getUserChats(String currentUserId) async {
    try {
      final chatParticipantRows = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId);
      final chatIds = (chatParticipantRows as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['chat_id'] as String)
          .toSet();

      final List<ChatSummary> chats = [];
      for (final chatId in chatIds) {
        final participantRows = await _supabase
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId);
        final participantIds = (participantRows as List<dynamic>)
            .map((row) => (row as Map<String, dynamic>)['user_id'] as String)
            .toList();

        final otherUserId = participantIds.firstWhere(
          (id) => id != currentUserId,
          orElse: () => currentUserId,
        );

        final otherUserRow = await _supabase
            .from('users')
            .select('id, full_name')
            .eq('id', otherUserId)
            .maybeSingle();

        final otherUserMap = otherUserRow as Map<String, dynamic>?;
        final otherName = otherUserMap != null
            ? otherUserMap['full_name'] as String
            : 'Unknown';

        final lastMessageRows = await _supabase
            .from('messages')
            .select('content, created_at')
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1);

        String? lastMessage;
        DateTime? lastMessageAt;
        if (lastMessageRows is List && lastMessageRows.isNotEmpty) {
          final msgMap = lastMessageRows.first as Map<String, dynamic>;
          lastMessage = msgMap['content'] as String?;
          if (msgMap['created_at'] != null) {
            lastMessageAt = DateTime.parse(msgMap['created_at'] as String);
          }
        }

        chats.add(ChatSummary(
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserName: otherName,
          lastMessage: lastMessage,
          lastMessageAt: lastMessageAt,
          hasUnread: false,
        ));
      }

      chats.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return chats;
    } catch (error) {
      throw Exception('Failed to fetch chats: $error');
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, full_name, email')
          .ilike('full_name', '%$query%')
          .neq('id', currentUserId)
          .limit(50);

      return List<Map<String, dynamic>>.from(response as List<dynamic>);
    } catch (e) {
      throw Exception('Could not search users: $e');
    }
  }

  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    final existing = await findChatByUsers(currentUserId, otherUserId);
    if (existing != null) return existing;

    final chatId = _uuid.v4();
    await _supabase.from('chats').insert({'id': chatId});
    await _supabase.from('chat_participants').insert([
      {'chat_id': chatId, 'user_id': currentUserId, 'joined_at': DateTime.now().toIso8601String()},
      {'chat_id': chatId, 'user_id': otherUserId, 'joined_at': DateTime.now().toIso8601String()},
    ]);
    return chatId;
  }

  Future<String?> findChatByUsers(String userA, String userB) async {
    try {
      final firstResponse = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', userA);
      final chatIds = (firstResponse as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['chat_id'] as String)
          .toSet();

      if (chatIds.isEmpty) return null;

      final secondResponse = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', userB);

      final secondIds = (secondResponse as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['chat_id'] as String)
          .toSet();

      final matched = chatIds.intersection(secondIds);
      return matched.isNotEmpty ? matched.first : null;
    } catch (e) {
      throw Exception('Failed to find chat: $e');
    }
  }
}
