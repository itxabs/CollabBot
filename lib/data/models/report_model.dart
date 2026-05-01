class ReportModel {
  final String? id;
  final String reporterId;
  final String? targetUserId;
  final String? targetContentId;
  final String contentType; // 'user', 'question', 'answer', 'message'
  final String reason;
  final String? description;
  final String status;
  final DateTime? createdAt;

  ReportModel({
    this.id,
    required this.reporterId,
    this.targetUserId,
    this.targetContentId,
    required this.contentType,
    required this.reason,
    this.description,
    this.status = 'pending',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reporter_id': reporterId,
      'target_user_id': targetUserId,
      'target_content_id': targetContentId,
      'content_type': contentType,
      'reason': reason,
      'description': description,
      'status': status,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'],
      reporterId: map['reporter_id'],
      targetUserId: map['target_user_id'],
      targetContentId: map['target_content_id'],
      contentType: map['content_type'],
      reason: map['reason'],
      description: map['description'],
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
