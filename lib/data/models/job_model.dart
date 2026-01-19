class JobModel {
  final String jobId;
  final String title;
  final String description;
  final String employmentType;
  final String location;
  final String salaryRange;
  final String experienceRequired;
  final List<String> skillsRequired;
  final DateTime postedDate;

  JobModel({
    required this.jobId,
    required this.title,
    required this.description,
    required this.employmentType,
    required this.location,
    required this.salaryRange,
    required this.experienceRequired,
    required this.skillsRequired,
    required this.postedDate,
  });

  /// JSON → Dart
  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      jobId: json['job_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      employmentType: json['employment_type'] as String,
      location: json['location'] as String,
      salaryRange: json['salary_range'] as String,
      experienceRequired: json['experience_required'] as String,
      skillsRequired:
          List<String>.from(json['skills_required'] ?? []),
      postedDate: DateTime.parse(json['posted_date']),
    );
  }

  /// Dart → JSON (insert / update)
  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'title': title,
      'description': description,
      'employment_type': employmentType,
      'location': location,
      'salary_range': salaryRange,
      'experience_required': experienceRequired,
      'skills_required': skillsRequired,
      'posted_date': postedDate.toIso8601String(),
    };
  }
}
