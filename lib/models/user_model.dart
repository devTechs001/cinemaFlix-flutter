class UserModel {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final String bio;
  final String website;
  final String location;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    this.bio = '',
    this.website = '',
    this.location = '',
    required this.createdAt,
  });

  bool get isAdmin => email.toLowerCase() == 'devtechs842@gmail.com';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? map['user_id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      username: (map['username'] ?? 'Cinema Fan').toString(),
      avatarUrl: (map['avatar_url'] ?? map['avatarUrl'])?.toString(),
      bio: (map['bio'] ?? '').toString(),
      website: (map['website'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
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
      'bio': bio,
      'website': website,
      'location': location,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    String? bio,
    String? website,
    String? location,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      website: website ?? this.website,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
