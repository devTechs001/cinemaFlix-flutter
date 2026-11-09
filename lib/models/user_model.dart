class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isAdmin => email.toLowerCase() == 'devtechs842@gmail.com';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? map['user_id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      username: (map['username'] ?? 'Cinema Fan').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatarUrl'])?.toString(),
      createdAt:
          DateTime.tryParse(
            (map['created_at'] ??
                    map['createdAt'] ??
                    DateTime.now().toIso8601String())
                .toString(),
          ) ??
          DateTime.now(),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
