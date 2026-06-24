class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final DateTime? dob;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.dob,
    required this.createdAt,
  });
 
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UserSkill {
  final String id;
  // user_id is implicit if part of a list for a user, but good to have
  final String userId; 
  final String skillName;
  final String skillLevelId;
  final bool isVerified;
  final DateTime createdAt;

  UserSkill({
    required this.id,
    required this.userId,
    required this.skillName,
    required this.skillLevelId,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      skillName: json['skill_name'] as String,
      skillLevelId: json['skill_level_id'].toString(),
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Experience {
  final String id;
  final String userId;
  final String organization;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;

  Experience({
    required this.id,
    required this.userId,
    required this.organization,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      organization: json['organization'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
    );
  }
}

class SkillLevel {
  final String id;
  final String name;

  SkillLevel({required this.id, required this.name});

  factory SkillLevel.fromJson(Map<String, dynamic> json) {
    return SkillLevel(
      id: json['id'].toString(),
      name: json['name'] as String,
    );
  }
}

class UserSocialLink {
  final String id;
  final String userId;
  final String platform;
  final String url;
  final DateTime createdAt;

  UserSocialLink({
    required this.id,
    required this.userId,
    required this.platform,
    required this.url,
    required this.createdAt,
  });

  factory UserSocialLink.fromJson(Map<String, dynamic> json) {
    return UserSocialLink(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      platform: json['platform'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Education {
  final String id;
  final String userId;
  final String institution;
  final String? degree;
  final String? fieldOfStudy;
  final int? startYear;
  final int? endYear;

  Education({
    required this.id,
    required this.userId,
    required this.institution,
    this.degree,
    this.fieldOfStudy,
    this.startYear,
    this.endYear,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      institution: json['institution'] as String,
      degree: json['degree'] as String?,
      fieldOfStudy: json['field_of_study'] as String?,
      startYear: json['start_year'] as int?,
      endYear: json['end_year'] as int?,
    );
  }
}
