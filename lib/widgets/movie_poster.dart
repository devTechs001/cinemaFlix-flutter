import 'package:flutter/material.dart';
import '../models/movie.dart';

/// Poster artwork for a [Movie]: loads the real poster image over the
/// per-movie gradient artwork, which stays visible while loading and
/// whenever the image is missing/fails (offline, wrong URL, etc.).
class MoviePoster extends StatelessWidget {
  final Movie movie;
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;

  /// Dark gradient at the bottom so overlaid titles stay readable.
  final bool scrim;

  const MoviePoster({
    super.key,
    required this.movie,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.scrim = false,
  });

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [movie.gradientStart, movie.gradientEnd],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_filter_outlined,
          color: Colors.white.withAlpha(50),
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = movie.posterUrl;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _fallback(),
            if (url != null && url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: '${movie.title} poster',
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _fallback(),
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
            if (scrim)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(90),
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.35, 0.7, 1.0],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
