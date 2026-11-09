import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/globals.dart';
import 'movie_poster.dart';

/// Full-bleed wall of movie poster cards that drifts slowly sideways —
/// the Netflix-intro-style backdrop behind the splash and onboarding
/// screens.
///
/// Reads the live [movieService] catalogue (bundled movies instantly,
/// Supabase rows when available) and renders every card through
/// [MoviePoster], so a dead poster URL degrades to gradient artwork
/// instead of a broken image. Rows alternate drift direction for depth.
class MovieCardWall extends StatefulWidget {
  /// Overall visibility of the wall (a dark scrim usually sits above it).
  final double opacity;

  /// Tilt of each card row, in radians.
  final double angle;

  final double cardWidth;
  final double cardHeight;

  /// Time for one full drift cycle (one catalogue period).
  final Duration duration;

  const MovieCardWall({
    super.key,
    this.opacity = 0.45,
    this.angle = -0.14,
    this.cardWidth = 92,
    this.cardHeight = 138,
    this.duration = const Duration(seconds: 45),
  });

  @override
  State<MovieCardWall> createState() => _MovieCardWallState();
}

class _MovieCardWallState extends State<MovieCardWall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movies = movieService.movies;
    if (movies.isEmpty) return const SizedBox.shrink();

    final step = widget.cardWidth + 12;
    final period = step * movies.length;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Enough cards to cover the screen plus two full periods so the
    // loop is seamless at any translation.
    final count = ((screenWidth + period * 2) / step).ceil();

    return Opacity(
      opacity: widget.opacity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _drift,
          builder: (context, _) {
            final t = _drift.value % 1.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildRow(
                  movies: movies,
                  count: count,
                  step: step,
                  period: period,
                  t: t,
                  reverse: false,
                  top: 8.0,
                  offset: 0,
                ),
                _buildRow(
                  movies: movies,
                  count: count,
                  step: step,
                  period: period,
                  t: t,
                  reverse: true,
                  top: MediaQuery.sizeOf(context).height * 0.34,
                  offset: 5,
                ),
                _buildRow(
                  movies: movies,
                  count: count,
                  step: step,
                  period: period,
                  t: t,
                  reverse: false,
                  top: MediaQuery.sizeOf(context).height * 0.68,
                  offset: 11,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow({
    required List<Movie> movies,
    required int count,
    required double step,
    required double period,
    required double t,
    required bool reverse,
    required double top,
    required int offset,
  }) {
    // Content repeats the catalogue, so translating by exactly one
    // catalogue period loops seamlessly.
    final x = reverse ? -period + t * period : -t * period;
    return Positioned(
      top: top,
      left: 0,
      child: Transform.rotate(
        angle: widget.angle,
        alignment: Alignment.center,
        child: Transform.translate(
          offset: Offset(x, 0),
          child: Row(
            children: [
              for (var i = 0; i < count; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MoviePoster(
                      movie: movies[(i + offset) % movies.length],
                      width: widget.cardWidth,
                      height: widget.cardHeight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
