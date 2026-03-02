class UserModel {
  final String userId;
  final String userEmail;
  final String name;
  final String role;
  final DateTime? dob;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.userEmail,
    required this.name,
    required this.role,
    this.dob,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] as String,
      userEmail: json['email'] as String,
      name: json['full_name'] as String,
      role: json['role'] as String,
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
      'dob': dob?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}


