class JobModel {
  final String id;
  final String creatorId;
  final String title;
  final String company;
  final String description;
  final String location;
  final String salaryRange;
  final String employmentType; // e.g. Full-time, Part-time, Internship
  final String experienceLevel; // e.g. Junior, Mid, Senior
  final List<String> requirements;
  final List<String> skills;
  final DateTime createdAt;
  final DateTime? deadline;
  final String status; // Approved, Pending, Rejected
  final bool isRemote;
  
  // UI State fields (not necessarily in the jobs table)
  bool isSaved;
  bool isApplied;
  String? applicationStatus; // Pending, Viewed, Shortlisted, Rejected

  JobModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.salaryRange,
    required this.employmentType,
    required this.experienceLevel,
    required this.requirements,
    required this.skills,
    required this.createdAt,
    this.deadline,
    required this.status,
    this.isRemote = false,
    this.isSaved = false,
    this.isApplied = false,
    this.applicationStatus,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String? ?? json['job_id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      company: json['company'] as String? ?? 'Unknown Company',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      salaryRange: json['salary_range'] as String? ?? '',
      employmentType: json['employment_type'] as String? ?? 'Full-time',
      experienceLevel: json['experience_level'] as String? ?? 'Junior',
      requirements: List<String>.from(json['requirements'] ?? []),
      skills: List<String>.from(json['skills'] ?? json['skills_required'] ?? []),
      createdAt: DateTime.tryParse(json['created_at'] ?? json['posted_date'] ?? '') ?? DateTime.now(),
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      status: (json['status_info'] as Map?)?['name'] as String? ?? json['status'] as String? ?? 'Approved',
      isRemote: json['is_remote'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'description': description,
      'location': location,
      'salary_range': salaryRange,
      'employment_type': employmentType,
      'experience_level': experienceLevel,
      'requirements': requirements,
      'skills': skills,
      'creator_id': creatorId,
      'status_id': 1, // 1 = Pending
      'is_remote': isRemote,
      'created_at': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
    };
  }
}
