class UserModel {
  final String userId;
  final String userEmail;
  final String name;
  final String role;
  final int reputation;
  final String? avatarUrl;
  final DateTime? dob;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.userEmail,
    required this.name,
    required this.role,
    this.reputation = 0,
    this.avatarUrl,
    this.dob,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] as String,
      userEmail: json['email'] as String,
      name: json['full_name'] as String,
      role: json['role'] as String,
      reputation: _toInt(json['reputation']),
      avatarUrl: json['avatar_url'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'email': userEmail,
      'full_name': name,
      'role': role,
      'reputation': reputation,
      'avatar_url': avatarUrl,
      'dob': dob?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
