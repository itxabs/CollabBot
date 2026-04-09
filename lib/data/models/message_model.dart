import 'attachment_model.dart';

enum MessageStatus { pending, sending, sent, failed }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final List<AttachmentModel> attachments;
  final String status;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
    String? status,
  }) : status = status ?? MessageStatus.sent.name;

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    List<AttachmentModel>? attachments,
    String? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['message_attachments'] as List<dynamic>?;
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: attachmentsJson != null
          ? attachmentsJson
              .map((item) => AttachmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList()
          : [],
      status: (json['status'] as String?) ?? MessageStatus.sent.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'status': status,
    };
  }
}

class LocalMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final List<AttachmentModel> attachments;
  final String status;

  LocalMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
    String? status,
  }) : status = status ?? MessageStatus.pending.name;

  LocalMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    List<AttachmentModel>? attachments,
    String? status,
  }) {
    return LocalMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
    );
  }

  factory LocalMessage.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>?;
    return LocalMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: attachmentsJson != null
          ? attachmentsJson
              .map((item) => AttachmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList()
          : [],
      status: (json['status'] as String?) ?? MessageStatus.pending.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'status': status,
    };
  }
}
