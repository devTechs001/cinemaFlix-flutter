class ChatMessageModel {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final String? avatarUrl;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      username: map['username'] as String? ?? 'Anonymous',
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
}
