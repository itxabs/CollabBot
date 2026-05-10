class ChatPresenceService {
  ChatPresenceService._();
  static final ChatPresenceService instance = ChatPresenceService._();

  String? _activeChatId;

  String? get activeChatId => _activeChatId;

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
  }

  void clearActiveChat(String chatId) {
    if (_activeChatId == chatId) {
      _activeChatId = null;
    }
  }
}
