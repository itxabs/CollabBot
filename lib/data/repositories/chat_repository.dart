import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatRepository {
  final ChatService _service;

  ChatRepository(this._service);

  Future<List<ChatSummary>> getUserChats(String currentUserId) async {
    return await _service.getUserChats(currentUserId);
  }

  Stream<List<Map<String, dynamic>>> subscribeToAllMessages() {
    return _service.subscribeToAllMessages();
  }

  Future<String> getUserNameById(String userId) async {
    return await _service.getUserNameById(userId);
  }

  Future<bool> isParticipant(String chatId, String userId) async {
    return await _service.isParticipant(chatId, userId);
  }

  Future<void> leaveChat(String chatId, String userId) async {
    await _service.leaveChat(chatId, userId);
  }
}
