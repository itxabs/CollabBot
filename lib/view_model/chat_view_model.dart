import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/message_model.dart';
import '../data/services/message_service.dart';
import '../local_db/local_message_db.dart';

class ChatViewModel extends ChangeNotifier {
  final String chatId;
  final String otherUserName;
  final SupabaseClient _supabase = Supabase.instance.client;
  late final MessageService _messageService;

  bool isLoading = false;
  String? errorMessage;
  List<LocalMessage> messages = [];
  StreamSubscription<dynamic>? _subscription;

  ChatViewModel({required this.chatId, required this.otherUserName}) {
    _messageService = MessageService(_supabase);
    loadMessages();
    subscribeRealtime();
  }

  Future<void> loadMessages() async {
    isLoading = true;
    notifyListeners();
    try {
      final localMessages = await LocalMessageDb.instance.getMessagesForChat(chatId);
      messages = localMessages;

      final currentUser = _supabase.auth.currentUser;
      final remoteMessages = await _messageService.fetchLastMessages(chatId, limit: 100);
      for (final remote in remoteMessages) {
        final exists = messages.any((m) => m.id == remote.id);
        if (!exists && remote.senderId != currentUser?.id) {
          final local = LocalMessage(
            id: remote.id,
            chatId: remote.chatId,
            senderId: remote.senderId,
            content: remote.content,
            createdAt: remote.createdAt,
          );
          await LocalMessageDb.instance.saveMessage(local);
          messages.add(local);
          await _messageService.deleteMessageFromSupabase(remote.id);
        }
      }
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      errorMessage = 'Failed to read messages: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      errorMessage = 'User signed out';
      notifyListeners();
      return;
    }
    if (content.trim().isEmpty) return;
    try {
      final sent = await _messageService.sendMessage(
        chatId: chatId,
        senderId: currentUser.id,
        content: content.trim(),
      );
      final local = LocalMessage(
        id: sent.id,
        chatId: sent.chatId,
        senderId: sent.senderId,
        content: sent.content,
        createdAt: sent.createdAt,
      );
      await LocalMessageDb.instance.saveMessage(local);
      if (!messages.any((m) => m.id == local.id)) {
        messages.add(local);
      }
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    } catch (e) {
      errorMessage = 'Could not send message: $e';
      notifyListeners();
    }
  }

  void subscribeRealtime() {
    _subscription?.cancel();
    final stream = _supabase
        .from('messages:chat_id=eq.$chatId')
        .stream(primaryKey: ['id']);

    _subscription = stream.listen((event) async {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;
      final rows = event as List<dynamic>;
      for (final raw in rows) {
        final payload = Map<String, dynamic>.from(raw as Map);
        final senderId = payload['sender_id'] as String;
        if (senderId == currentUser.id) continue;
        final message = LocalMessage(
          id: payload['id'] as String,
          chatId: payload['chat_id'] as String,
          senderId: senderId,
          content: payload['content'] as String,
          createdAt: DateTime.parse(payload['created_at'] as String),
        );
        await LocalMessageDb.instance.saveMessage(message);
        await _messageService.deleteMessageFromSupabase(message.id);
        if (!messages.any((m) => m.id == message.id)) {
          messages.add(message);
        }
      }
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    }, onError: (e) {
      errorMessage = 'Realtime error: $e';
      notifyListeners();
    });
  }

  Future<void> markRead() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;
    await LocalMessageDb.instance.setLastReadAt(chatId, currentUser.id, DateTime.now());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
