import 'package:path/path.dart' as p;

enum AttachmentDownloadState { notDownloaded, downloading, downloaded, failed }

class AttachmentModel {
  final String id;
  final String messageId;
  final String fileUrl;
  final String fileName;
  final String extension;
  final String downloadState;
  final String? localPath;
  final DateTime createdAt;

  AttachmentModel({
    required this.id,
    required this.messageId,
    required this.fileUrl,
    required this.fileName,
    required this.extension,
    required this.downloadState,
    this.localPath,
    required this.createdAt,
  });

  bool get isDownloaded => downloadState == AttachmentDownloadState.downloaded.name && localPath != null;

  bool get isImage {
    final lower = extension.toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'].contains(lower);
  }

  AttachmentModel copyWith({
    String? id,
    String? messageId,
    String? fileUrl,
    String? fileName,
    String? extension,
    String? downloadState,
    String? localPath,
    DateTime? createdAt,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      extension: extension ?? this.extension,
      downloadState: downloadState ?? this.downloadState,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    final rawName = json['file_name'] as String?;
    final fileUrl = json['file_url'] as String;
    final fileName = rawName ?? p.basename(fileUrl);
    final extension = p.extension(fileName).isEmpty ? '.bin' : p.extension(fileName);
    return AttachmentModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      fileUrl: fileUrl,
      fileName: fileName,
      extension: extension,
      downloadState: json['download_state'] as String? ?? AttachmentDownloadState.notDownloaded.name,
      localPath: json['local_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'file_url': fileUrl,
      'file_name': fileName,
      'download_state': downloadState,
      'local_path': localPath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
