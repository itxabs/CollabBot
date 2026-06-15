class ChatSummary {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String? otherUserRole;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final bool isLastMessageMine;
  final bool hasUnread;

  ChatSummary({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.otherUserRole,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.isLastMessageMine = false,
    this.hasUnread = false,
  });

  factory ChatSummary.fromJson(Map<String, dynamic> json) {
    return ChatSummary(
      chatId: json['chat_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUserName: json['other_user_name'] as String,
      otherUserAvatarUrl: json['other_user_avatar_url'] as String?,
      otherUserRole: json['other_user_role'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      isLastMessageMine: json['is_last_message_mine'] == true,
      hasUnread: json['has_unread'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar_url': otherUserAvatarUrl,
      'other_user_role': otherUserRole,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender_id': lastMessageSenderId,
      'is_last_message_mine': isLastMessageMine,
      'has_unread': hasUnread,
    };
  }
}
