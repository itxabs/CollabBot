class JobModel {
  final String id;
  final String creatorId;
  final String title;
  final String jobUrl;
  final DateTime createdAt;
  final String status; // Approved, Pending, Rejected
  
  // UI State fields (not necessarily in the jobs table)
  bool isSaved;

  JobModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.jobUrl,
    required this.createdAt,
    required this.status,
    this.isSaved = false,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String? ?? json['job_id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      jobUrl: json['job_url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['posted_date'] ?? '') ?? DateTime.now(),
      status: (json['status_info'] as Map?)?['name'] as String? ?? json['status'] as String? ?? 'Approved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'job_url': jobUrl,
      'creator_id': creatorId,
      'status_id': 1, // 1 = Pending
      'created_at': createdAt.toIso8601String(),
    };
  }
}
