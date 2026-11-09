import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/globals.dart';
import 'movie_poster.dart';

/// Full-bleed wall of movie poster cards that drifts sideways —
/// the Netflix-intro-style backdrop behind splash and onboarding.
///
/// Cards stagger in (scale + fade) so the wall *loads* instead of
/// popping on, then loops. Rows alternate direction for depth.
class MovieCardWall extends StatefulWidget {
  /// Overall visibility of the wall (a dark scrim usually sits above it).
  final double opacity;

  /// Tilt of each card row, in radians.
  final double angle;

  final double cardWidth;
  final double cardHeight;

  /// Time for one full drift cycle (one catalogue period).
  final Duration duration;

  /// How long the staggered “posters loading” intro lasts.
  final Duration appearDuration;

  const MovieCardWall({
    super.key,
    this.opacity = 0.45,
    this.angle = -0.16,
    this.cardWidth = 96,
    this.cardHeight = 144,
    this.duration = const Duration(seconds: 22),
    this.appearDuration = const Duration(milliseconds: 1600),
  });

  @override
  State<MovieCardWall> createState() => _MovieCardWallState();
}

class _MovieCardWallState extends State<MovieCardWall>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _appear;

  static const _palette = <(Color, Color)>[
    (Color(0xFF7F1D1D), Color(0xFF1A0505)),
    (Color(0xFF1E3A8A), Color(0xFF0B1220)),
    (Color(0xFF4A044E), Color(0xFF140016)),
    (Color(0xFF14532D), Color(0xFF052E16)),
    (Color(0xFF7C2D12), Color(0xFF1C0A00)),
    (Color(0xFF0F766E), Color(0xFF042F2E)),
  ];

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: widget.duration)..repeat();
    _appear = AnimationController(vsync: this, duration: widget.appearDuration)..forward();
  }

  @override
  void didUpdateWidget(covariant MovieCardWall old) {
    super.didUpdateWidget(old);
    if (old.duration != widget.duration) {
      _drift.duration = widget.duration;
      if (!_drift.isAnimating) _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    _appear.dispose();
    super.dispose();
  }

  List<Movie> get _movies {
    final live = movieService.movies;
    if (live.isNotEmpty) return live;
    return [
      for (var i = 0; i < _palette.length)
        Movie(
          id: 'wall-$i',
          title: 'CinemaFlix',
          gradientStart: _palette[i].$1,
          gradientEnd: _palette[i].$2,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final movies = _movies;
    final size = MediaQuery.sizeOf(context);
    final step = widget.cardWidth + 12;
    final period = math.max(step * movies.length, step * 8);
    final count = ((size.width + period * 2) / step).ceil();
    final stride = widget.cardHeight * 0.58;
    var rows = (size.height / stride).ceil();
    if (rows < 4) rows = 4;
    if (rows > 6) rows = 6;

    return Opacity(
      opacity: widget.opacity,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: Listenable.merge([_drift, _appear]),
          builder: (context, _) {
            final t = _drift.value % 1.0;
            final appear = Curves.easeOutCubic.transform(_appear.value);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var r = 0; r < rows)
                  _buildRow(
                    movies: movies,
                    count: count,
                    step: step,
                    period: period,
                    t: t,
                    reverse: r.isOdd,
                    top: 4.0 + r * stride - 20,
                    offset: r * 7,
                    rowIndex: r,
                    appear: appear,
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
    required int rowIndex,
    required double appear,
  }) {
    final x = reverse ? -period + t * period : -t * period;
    final rowDelay = (rowIndex * 0.08).clamp(0.0, 0.4);
    final rowT = ((appear - rowDelay) / (1.0 - rowDelay)).clamp(0.0, 1.0);
    return Positioned(
      top: top,
      left: 0,
      child: Opacity(
        opacity: rowT,
        child: Transform.translate(
          offset: Offset(0, (1 - rowT) * 28),
          child: Transform.rotate(
            angle: widget.angle,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(x, 0),
              child: Row(
                children: [
                  for (var i = 0; i < count; i++)
                    _card(
                      movie: movies[(i + offset) % movies.length],
                      index: i,
                      rowIndex: rowIndex,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Movie movie,
    required int index,
    required int rowIndex,
  }) {
    final slot = (index + rowIndex * 3) % 14;
    final delayed = ((_appear.value - slot * 0.045) / 0.55).clamp(0.0, 1.0);
    final bounced = Curves.easeOutBack.transform(delayed);
    final local = bounced.clamp(0.0, 1.0);
    final scale = 0.78 + 0.22 * bounced.clamp(0.0, 1.18);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Opacity(
        opacity: local,
        child: Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(90),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: MoviePoster(
                movie: movie,
                width: widget.cardWidth,
                height: widget.cardHeight,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
