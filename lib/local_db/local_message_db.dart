import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/message_model.dart';
import '../data/models/chat_model.dart';

class LocalMessageDb {
  static const String _messagesBox = 'local_messages';
  static const String _readBox = 'local_read';
  static const String _chatsBox = 'local_chats';

  LocalMessageDb._();
  static final LocalMessageDb instance = LocalMessageDb._();

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<dynamic>(_messagesBox);
    await Hive.openBox<String>(_readBox);
    await Hive.openBox<dynamic>(_chatsBox);
  }

  Future<void> saveMessage(LocalMessage message) async {
    final box = Hive.box<dynamic>(_messagesBox);
    final chatBoxName = _storageKeyForChat(message.chatId);
    final existing = box.get(chatBoxName) as List<dynamic>?;
    final messageList = existing != null 
        ? (existing as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
        : <Map<String, dynamic>>[];
    final existingIndex = messageList.indexWhere((item) => item['id'] == message.id);
    if (existingIndex >= 0) {
      messageList[existingIndex] = message.toJson();
    } else {
      messageList.add(message.toJson());
    }
    await box.put(chatBoxName, messageList);
  }

  Future<void> updateMessage(LocalMessage message) async {
    await saveMessage(message);
  }

  Future<List<LocalMessage>> getMessagesForChat(String chatId) async {
    final box = Hive.box<dynamic>(_messagesBox);
    final stored = box.get(_storageKeyForChat(chatId));
    if (stored == null) return [];
    final list = List<dynamic>.from(stored as List);
    final messages = list
        .map((item) => LocalMessage.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<LocalMessage?> getLastMessage(String chatId) async {
    final messages = await getMessagesForChat(chatId);
    if (messages.isEmpty) return null;
    return messages.last;
  }

  Future<int> getUnreadCount(String chatId, String userId) async {
    final lastRead = await getLastReadAt(chatId, userId);
    if (lastRead == null) {
      final messages = await getMessagesForChat(chatId);
      return messages.where((m) => m.senderId != userId).length;
    }
    final messages = await getMessagesForChat(chatId);
    return messages.where((m) => m.senderId != userId && m.createdAt.isAfter(lastRead)).length;
  }

  Future<void> setLastReadAt(String chatId, String userId, DateTime time) async {
    final box = Hive.box<String>(_readBox);
    await box.put(_readStorageKey(chatId, userId), time.toIso8601String());
  }

  Future<DateTime?> getLastReadAt(String chatId, String userId) async {
    final box = Hive.box<String>(_readBox);
    final value = box.get(_readStorageKey(chatId, userId));
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  String _storageKeyForChat(String chatId) => 'chat_$chatId';
  String _readStorageKey(String chatId, String userId) => 'read_${chatId}_$userId';

  Future<void> saveUserChats(String userId, List<ChatSummary> chats) async {
    final box = Hive.box<dynamic>(_chatsBox);
    final data = chats.map((chat) => chat.toJson()).toList();
    await box.put(userId, data);
  }

  Future<List<ChatSummary>> getUserChats(String userId) async {
    final box = Hive.box<dynamic>(_chatsBox);
    final stored = box.get(userId);
    if (stored == null) return [];
    final list = List<dynamic>.from(stored as List);
    return list
        .map((item) => ChatSummary.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
