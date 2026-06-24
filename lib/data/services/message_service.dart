import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../local_db/local_message_db.dart';
import '../models/attachment_model.dart';
import '../models/message_model.dart';
import 'attachment_service.dart';

class MessageService {
  final SupabaseClient _supabase;
  late final AttachmentService _attachmentService;

  MessageService(this._supabase) {
    _attachmentService = AttachmentService(_supabase);
  }

  AttachmentService get attachmentService => _attachmentService;

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    List<File>? attachments,
    double? latitude,
    double? longitude,
    String? messageId,
  }) async {
    final id = messageId ?? const Uuid().v4();
    final createdAt = DateTime.now().toIso8601String();
    
    // Encode location into content to avoid needing extra columns in the database
    String finalContent = content;
    if (latitude != null && longitude != null) {
      finalContent = '[LOC:$latitude,$longitude]$content';
    }

    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'id': id,
            'chat_id': chatId,
            'sender_id': senderId,
            'content': finalContent,
            'created_at': createdAt,
          })
          .select()
          .single();

      final inserted = response;
      final realMessageId = inserted['id'] as String;
      final attachmentModels = attachments != null && attachments.isNotEmpty
          ? await _uploadAttachments(realMessageId, chatId, attachments)
          : <AttachmentModel>[];

      return MessageModel(
        id: realMessageId,
        chatId: inserted['chat_id'] as String,
        senderId: inserted['sender_id'] as String,
        content: inserted['content'] as String,
        createdAt: DateTime.parse(inserted['created_at'] as String),
        attachments: attachmentModels,
        latitude: inserted['latitude'] == null
            ? null
            : (inserted['latitude'] as num).toDouble(),
        longitude: inserted['longitude'] == null
            ? null
            : (inserted['longitude'] as num).toDouble(),
      );
    } catch (e) {
      try {
        await _supabase.from('messages').delete().eq('id', id);
      } catch (_) {
        // ignore cleanup failure
      }
      throw Exception('Failed to send message: $e');
    }
  }

  Future<List<AttachmentModel>> _uploadAttachments(
    String messageId,
    String chatId,
    List<File> files,
  ) async {
    final uploaded = await _attachmentService.uploadFiles(
      chatId: chatId,
      messageId: messageId,
      files: files,
    );
    try {
      final rows = uploaded
          .map(
            (attachment) => {
              'id': attachment.id,
              'message_id': messageId,
              'file_url': attachment.fileUrl,
              'file_name': attachment.fileName,
              'download_state': attachment.downloadState,
              'created_at': attachment.createdAt.toIso8601String(),
            },
          )
          .toList();
      final inserted = await _supabase
          .from('message_attachments')
          .insert(rows)
          .select();
      return List<dynamic>.from(inserted as List<dynamic>)
          .map(
            (item) => AttachmentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (e) {
      await _deleteUploadedPaths(uploaded);
      throw Exception('Failed to persist attachment metadata: $e');
    }
  }

  Future<void> _deleteUploadedPaths(List<AttachmentModel> attachments) async {
    for (final attachment in attachments) {
      try {
        await _supabase.storage.from(_attachmentService.storageBucket).remove([
          attachment.fileUrl,
        ]);
      } catch (_) {
        // ignore cleanup failure
      }
    }
  }

  Future<bool> _chatExists(String chatId) async {
    final response = await _supabase
        .from('chats')
        .select('id')
        .eq('id', chatId)
        .maybeSingle();
    return response != null;
  }

  Future<bool> isParticipant(String chatId, String userId) async {
    try {
      final localChats = await LocalMessageDb.instance.getUserChats(userId);
      final existsLocally = localChats.any((chat) => chat.chatId == chatId);
      if (existsLocally) return true;
    } catch (e) {
      debugPrint('Error checking participant in local DB: $e');
    }

    final response = await _supabase
        .from('chat_participants')
        .select('user_id')
        .eq('chat_id', chatId)
        .eq('user_id', userId)
        .maybeSingle();
    return response != null;
  }

  Future<void> ensureParticipant(String chatId, String userId) async {
    try {
      final chatExists = await _chatExists(chatId);
      if (!chatExists) {
        await _supabase.from('chats').insert({'id': chatId});
      }

      final participantExists = await isParticipant(chatId, userId);
      if (!participantExists) {
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

  Stream<MessageModel> subscribeToMessages(String chatId) {
    final stream = _supabase
        .from('messages:chat_id=eq.$chatId')
        .stream(primaryKey: ['id']);

    return stream.expand((rows) {
      return (rows as List<dynamic>)
          .map(
            (item) =>
                MessageModel.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    });
  }

  Future<List<AttachmentModel>> fetchAttachmentsForMessage(
    String messageId,
  ) async {
    try {
      final response = await _supabase
          .from('message_attachments')
          .select()
          .eq('message_id', messageId);
      final list = List<dynamic>.from(response as List<dynamic>);
      return list
          .map(
            (json) => AttachmentModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('⚠️ Failed to fetch attachments: $e');
      return [];
    }
  }

  Future<void> deleteMessageFromSupabase(String messageId) async {
    try {
      print('🗑️ Deleting attachments for message $messageId...');
      await _supabase
          .from('message_attachments')
          .delete()
          .eq('message_id', messageId);

      print('🗑️ Deleting message $messageId from messages table...');
      await _supabase.from('messages').delete().eq('id', messageId);

      print('✅ Successfully deleted message $messageId from Supabase');
    } catch (e) {
      print('❌ Failed to delete message $messageId from Supabase: $e');
      throw Exception('Failed to delete message from Supabase: $e');
    }
  }

  Future<List<MessageModel>> fetchLastMessages(
    String chatId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select(
            'id, chat_id, sender_id, content, created_at, message_attachments(id, message_id, file_url, file_name, download_state, created_at)',
          )
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(limit);

      final list = List<dynamic>.from(response as List<dynamic>);
      return list
          .map(
            (json) =>
                MessageModel.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }
}
