class MovieModel {
  final String id;
  final String title;
  final String? genre;
  final String? year;
  final String? rating;
  final String? posterUrl;
  final String? description;
  final double? userRating;
  final bool isFavorited;
  final bool inWatchlist;

  MovieModel({
    required this.id,
    required this.title,
    this.genre,
    this.year,
    this.rating,
    this.posterUrl,
    this.description,
    this.userRating,
    this.isFavorited = false,
    this.inWatchlist = false,
  });

  factory MovieModel.fromMap(Map<String, dynamic> map) {
    return MovieModel(
      id: map['id'] as String,
      title: map['title'] as String,
      genre: map['genre'] as String?,
      year: map['year'] as String?,
      rating: map['rating'] as String?,
      posterUrl: map['poster_url'] as String?,
      description: map['description'] as String?,
      userRating: (map['user_rating'] as num?)?.toDouble(),
      isFavorited: map['is_favorited'] as bool? ?? false,
      inWatchlist: map['in_watchlist'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'genre': genre,
      'year': year,
      'rating': rating,
      'poster_url': posterUrl,
      'description': description,
    };
  }

  MovieModel copyWith({
    String? id,
    String? title,
    String? genre,
    String? year,
    String? rating,
    String? posterUrl,
    String? description,
    double? userRating,
    bool? isFavorited,
    bool? inWatchlist,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      posterUrl: posterUrl ?? this.posterUrl,
      description: description ?? this.description,
      userRating: userRating ?? this.userRating,
      isFavorited: isFavorited ?? this.isFavorited,
      inWatchlist: inWatchlist ?? this.inWatchlist,
    );
  }
}
