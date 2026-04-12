import 'attachment_model.dart';

enum MessageStatus { pending, sending, sent, failed }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final List<AttachmentModel> attachments;
  final double? latitude;
  final double? longitude;
  final String status;
  
  static double? _parseCoord(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
    this.latitude,
    this.longitude,
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
    double? latitude,
    double? longitude,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['message_attachments'] as List<dynamic>?;
    String rawContent = json['content'] as String;
    double? lat = _parseCoord(json['latitude']);
    double? lng = _parseCoord(json['longitude']);

    // Check if location is encoded in content (fallback for when columns don't exist)
    if (lat == null && lng == null && rawContent.startsWith('[LOC:')) {
      final endBracket = rawContent.indexOf(']');
      if (endBracket > 5) {
        final coordsStr = rawContent.substring(5, endBracket);
        final parts = coordsStr.split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0]);
          lng = double.tryParse(parts[1]);
          rawContent = rawContent.substring(endBracket + 1);
        }
      }
    }

    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: rawContent,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: attachmentsJson != null
          ? attachmentsJson
              .map((item) => AttachmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList()
          : [],
      latitude: lat,
      longitude: lng,
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
      'latitude': latitude,
      'longitude': longitude,
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
  final double? latitude;
  final double? longitude;
  final String status;

  LocalMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.attachments = const [],
    this.latitude,
    this.longitude,
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
    double? latitude,
    double? longitude,
  }) {
    return LocalMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
    );
  }

  factory LocalMessage.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>?;
    String rawContent = json['content'] as String;
    double? lat = MessageModel._parseCoord(json['latitude']);
    double? lng = MessageModel._parseCoord(json['longitude']);

    // Check if location is encoded in content
    if (lat == null && lng == null && rawContent.startsWith('[LOC:')) {
      final endBracket = rawContent.indexOf(']');
      if (endBracket > 5) {
        final coordsStr = rawContent.substring(5, endBracket);
        final parts = coordsStr.split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0]);
          lng = double.tryParse(parts[1]);
          rawContent = rawContent.substring(endBracket + 1);
        }
      }
    }

    return LocalMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: rawContent,
      createdAt: DateTime.parse(json['created_at'] as String),
      attachments: attachmentsJson != null
          ? attachmentsJson
              .map((item) => AttachmentModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList()
          : [],
      latitude: lat,
      longitude: lng,
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
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
