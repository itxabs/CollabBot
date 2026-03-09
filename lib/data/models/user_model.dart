class UserModel {
  final String userId;
  final String userEmail;
  final String name;
  final String role;
  final double rating;
  final DateTime dob;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.userEmail,
    required this.name,
    required this.role,
    required this.rating,
    required this.dob,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      userEmail: json['user_email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      rating: (json['rating'] as num).toDouble(),
      dob: DateTime.parse(json['dob']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_email': userEmail,
      'name': name,
      'role': role,
      'rating': rating,
      'dob': dob.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
