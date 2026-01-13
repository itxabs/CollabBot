class ProblemModel {
  final String problemId;
  final String title;
  final String description;
  final String status;
  final int upvotes;
  final DateTime postedDate;

  /// Attachments = list of file URLs (Supabase Storage)
  final List<String> attachments;

  ProblemModel({
    required this.problemId,
    required this.title,
    required this.description,
    required this.status,
    required this.upvotes,
    required this.postedDate,
    required this.attachments,
  });

  /// JSON → Dart
  factory ProblemModel.fromJson(Map<String, dynamic> json) {
    return ProblemModel(
      problemId: json['problem_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      upvotes: json['upvotes'] as int,
      postedDate: DateTime.parse(json['posted_date']),
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  /// Dart → JSON (insert / update)
  Map<String, dynamic> toJson() {
    return {
      'problem_id': problemId,
      'title': title,
      'description': description,
      'status': status,
      'upvotes': upvotes,
      'posted_date': postedDate.toIso8601String(),
      'attachments': attachments,
    };
  }
}
