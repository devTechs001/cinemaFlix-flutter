class ReviewModel {
  final String id;
  final String userId;
  final String movieId;
  final double rating;
  final String content;
  final DateTime createdAt;
  final String? username;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.username,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      movieId: map['movie_id'] as String,
      rating: (map['rating'] as num).toDouble(),
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      username: map['username'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'movie_id': movieId,
      'rating': rating,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
