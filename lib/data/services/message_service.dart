import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class MessageService {
  final SupabaseClient _supabase;

  MessageService(this._supabase);

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    final createdAt = DateTime.now().toIso8601String();
    try {
      final response = await _supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
        'created_at': createdAt,
      }).select().single();

      final inserted = response as Map<String, dynamic>;
      return MessageModel(
        id: inserted['id'] as String,
        chatId: inserted['chat_id'] as String,
        senderId: inserted['sender_id'] as String,
        content: inserted['content'] as String,
        createdAt: DateTime.parse(inserted['created_at'] as String),
      );
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Stream<MessageModel> subscribeToMessages(String chatId) {
    final stream = _supabase
        .from('messages:chat_id=eq.$chatId')
        .stream(primaryKey: ['id']);

    return stream.expand((rows) {
      return (rows as List<dynamic>)
          .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    });
  }

  Future<void> deleteMessageFromSupabase(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message from Supabase: $e');
    }
  }

  Future<List<MessageModel>> fetchLastMessages(String chatId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id, chat_id, sender_id, content, created_at')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(limit);

      final list = List<dynamic>.from(response as List<dynamic>);
      return list
          .map((json) => MessageModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }
}
