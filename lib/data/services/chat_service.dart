import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';

class ChatService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  ChatService(this._supabase);

  Stream<List<Map<String, dynamic>>> subscribeToAllMessages() {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map(
          (rows) => rows
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList(),
        );
  }

  Future<String> getUserNameById(String userId) async {
    final row = await _supabase
        .from('users')
        .select('full_name')
        .eq('id', userId)
        .maybeSingle();
    final map = row as Map<String, dynamic>?;
    return (map?['full_name'] as String?) ?? 'Unknown';
  }

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
            .select('id, full_name, avatar_url, role')
            .eq('id', otherUserId)
            .maybeSingle();

        final otherUserMap = otherUserRow as Map<String, dynamic>?;
        final otherName = otherUserMap != null
            ? otherUserMap['full_name'] as String
            : 'Unknown';
        final otherAvatarUrl = otherUserMap?['avatar_url'] as String?;
        final otherRole = otherUserMap?['role'] as String?;

        final lastMessageRows = await _supabase
            .from('messages')
            .select('content, created_at, sender_id')
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1);

        String? lastMessage;
        DateTime? lastMessageAt;
        String? lastMessageSenderId;
        if (lastMessageRows is List && lastMessageRows.isNotEmpty) {
          final msgMap = lastMessageRows.first as Map<String, dynamic>;
          lastMessage = msgMap['content'] as String?;
          lastMessageSenderId = msgMap['sender_id'] as String?;
          if (msgMap['created_at'] != null) {
            lastMessageAt = DateTime.parse(msgMap['created_at'] as String);
          }
        }

        chats.add(
          ChatSummary(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherName,
            otherUserAvatarUrl: otherAvatarUrl,
            otherUserRole: otherRole,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt,
            lastMessageSenderId: lastMessageSenderId,
            hasUnread: false,
          ),
        );
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

  Future<List<Map<String, dynamic>>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, full_name, email, role, avatar_url')
          .ilike('full_name', '%$query%')
          .neq('id', currentUserId)
          .neq('role', 'Admin')
          .limit(50);

      return List<Map<String, dynamic>>.from(response as List<dynamic>);
    } catch (e) {
      throw Exception('Could not search users: $e');
    }
  }

  Future<String> createOrGetChat(
    String currentUserId,
    String otherUserId,
  ) async {
    final existing = await findChatByUsers(currentUserId, otherUserId);
    if (existing != null) return existing;

    final chatId = _uuid.v4();
    await _supabase.from('chats').insert({'id': chatId});
    await _supabase.from('chat_participants').insert([
      {
        'chat_id': chatId,
        'user_id': currentUserId,
        'joined_at': DateTime.now().toIso8601String(),
      },
      {
        'chat_id': chatId,
        'user_id': otherUserId,
        'joined_at': DateTime.now().toIso8601String(),
      },
    ]);
    return chatId;
  }

  Future<void> leaveChat(String chatId, String userId) async {
    try {
      await _supabase
          .from('chat_participants')
          .delete()
          .eq('chat_id', chatId)
          .eq('user_id', userId);

      final remainingParticipants = await _supabase
          .from('chat_participants')
          .select('chat_id')
          .eq('chat_id', chatId);

      if (remainingParticipants is List && remainingParticipants.isEmpty) {
        await _supabase.from('chats').delete().eq('id', chatId);
      }
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  Future<bool> isParticipant(String chatId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', chatId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check participant: $e');
    }
  }

  Future<void> ensureParticipant(String chatId, String userId) async {
    try {
      final exists = await isParticipant(chatId, userId);
      if (!exists) {
        await _supabase.from('chat_participants').insert({
          'chat_id': chatId,
          'user_id': userId,
          'joined_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to restore participant: $e');
    }
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
