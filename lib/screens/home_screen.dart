import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../models/sample_movies.dart';
import '../widgets/interactive_card.dart';
import '../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialLoading = true;
  Set<String> _favorites = {};
  Set<String> _watchlist = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _userId => authService.currentUser?.id ?? guestService.guestId;

  Future<void> _loadData() async {
    if (guestService.isGuest || authService.currentUser == null) {
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      try {
        final favs = await databaseService.getFavorites(_userId);
        final watch = await databaseService.getWatchlist(_userId);
        _favorites = favs.map((m) => m.id).toSet();
        _watchlist = watch.map((m) => m.id).toSet();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  void _openMovie(BuildContext context, SampleMovie movie) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/movie-detail', arguments: movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InteractiveCard(
          onTap: () => Scaffold.of(context).openDrawer(),
          scaleAmount: 0.88,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.menu, color: Colors.white54),
          ),
        ),
        title: GestureDetector(
          onDoubleTap: () {
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎬 CinemaFlix v1.0'), duration: Duration(seconds: 1)),
            );
          },
          child: const Text(
            'CinemaFlix',
            style: TextStyle(
              color: Color(0xFFE50914),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
        actions: [
          InteractiveCard(
            onTap: () => Navigator.pushNamed(context, '/search'),
            scaleAmount: 0.88,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.search, color: Colors.white54),
            ),
          ),
          Stack(
            children: [
              InteractiveCard(
                onTap: () => Navigator.pushNamed(context, '/notifications'),
                scaleAmount: 0.88,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.notifications_outlined, color: Colors.white54),
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE50914),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE50914),
        onRefresh: _onRefresh,
        child: _initialLoading ? _buildShimmer() : _buildContent(),
      ),
    );
  }

  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const ShimmerFeatured(),
          const SizedBox(height: 24),
          _shimmerSectionHeader(),
          const ShimmerTrendingRow(),
          const SizedBox(height: 24),
          _shimmerSectionHeader(),
          const ShimmerTrendingRow(),
        ],
      ),
    );
  }

  Widget _shimmerSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const ShimmerLoading(width: 140, height: 20, borderRadius: 4),
          const ShimmerLoading(width: 50, height: 16, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturedSection(),
          const SizedBox(height: 24),
          _buildSectionHeader('Trending Now', () => Navigator.pushNamed(context, '/search')),
          _buildTrendingRow(),
          const SizedBox(height: 24),
          _buildSectionHeader('Continue Watching', () => Navigator.pushNamed(context, '/records')),
          _buildContinueWatching(),
          const SizedBox(height: 24),
          _buildSectionHeader('Popular on CinemaFlix', () => Navigator.pushNamed(context, '/search')),
          _buildPopularGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return SizedBox(
      height: 420,
      child: PageView.builder(
        itemCount: sampleMovies.length,
        itemBuilder: (context, index) {
          final movie = sampleMovies[index];
          final isFav = _favorites.contains(movie.id);
          final isWatch = _watchlist.contains(movie.id);

          return InteractiveCard(
            onTap: () => _openMovie(context, movie),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    movie.gradientStart,
                    movie.gradientEnd,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: movie.gradientStart.withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _buildIconButton(
                          Icons.favorite_border,
                          Icons.favorite,
                          isFav,
                          () async {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isFav) {
                                _favorites.remove(movie.id);
                              } else {
                                _favorites.add(movie.id);
                              }
                            });
                            if (!guestService.isGuest && authService.currentUser != null) {
                              await databaseService.toggleFavorite(_userId, movie.id,
                                title: movie.title, genre: movie.genre, year: movie.year, rating: movie.rating);
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFav ? 'Removed from favorites' : 'Added to favorites'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildIconButton(
                          Icons.bookmark_border,
                          Icons.bookmark,
                          isWatch,
                          () async {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isWatch) {
                                _watchlist.remove(movie.id);
                              } else {
                                _watchlist.add(movie.id);
                              }
                            });
                            if (!guestService.isGuest && authService.currentUser != null) {
                              await databaseService.toggleWatchlist(_userId, movie.id,
                                title: movie.title, genre: movie.genre, year: movie.year, rating: movie.rating);
                            }
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isWatch ? 'Removed from watchlist' : 'Added to watchlist'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildBadge(movie.rating, const Color(0xFFE50914)),
                            const SizedBox(width: 12),
                            Text(movie.year, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(width: 12),
                            Text(movie.genre, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  Navigator.pushNamed(context, '/movie-detail', arguments: movie);
                                },
                                icon: const Icon(Icons.play_arrow, size: 20),
                                label: const Text('Play'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE50914),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: () => _openMovie(context, movie),
                                icon: const Icon(Icons.info_outline, size: 18),
                                label: const Text('Details'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildIconButton(IconData outlined, IconData filled, bool isActive, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.85,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(80),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isActive ? filled : outlined,
          color: isActive ? const Color(0xFFE50914) : Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          InteractiveCard(
            onTap: () {
              HapticFeedback.lightImpact();
              onSeeAll();
            },
            child: const Text(
              'See All',
              style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingRow() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sampleMovies.length,
        itemBuilder: (context, index) {
          final movie = sampleMovies[index];
          final isFav = _favorites.contains(movie.id);

          return InteractiveCard(
            onTap: () => _openMovie(context, movie),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [movie.gradientStart, movie.gradientEnd],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(15),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Icon(
                          Icons.play_circle_outline,
                          color: const Color(0xFFE50914).withAlpha(180),
                          size: 36,
                        ),
                      ),
                        Positioned(
                        top: 0,
                        right: 0,
                        child: InteractiveCard(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isFav) {
                                _favorites.remove(movie.id);
                              } else {
                                _favorites.add(movie.id);
                              }
                            });
                            if (!guestService.isGuest && authService.currentUser != null) {
                              await databaseService.toggleFavorite(_userId, movie.id,
                                title: movie.title, genre: movie.genre, year: movie.year, rating: movie.rating);
                            }
                          },
                          scaleAmount: 0.8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(100),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? const Color(0xFFE50914) : Colors.white54,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      movie.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(movie.rating, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContinueWatching() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sampleMovies.length,
        itemBuilder: (context, index) {
          final movie = sampleMovies[index];
          final progress = ((index + 1) * 0.15).clamp(0.0, 1.0);

          return InteractiveCard(
            onTap: () => _openMovie(context, movie),
            child: Container(
              width: 220,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF2A2A2A),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        gradient: LinearGradient(
                          colors: [movie.gradientStart, movie.gradientEnd],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(Icons.play_circle_outline,
                                color: Colors.white.withAlpha(160), size: 44),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InteractiveCard(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: const Color(0xFF1F1F1F),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (_) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          width: 32, height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.playlist_remove, color: Colors.white54),
                                          title: const Text('Remove from Continue Watching', style: TextStyle(color: Colors.white)),
                                          onTap: () => Navigator.pop(context),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.check_circle_outline, color: Colors.white54),
                                          title: const Text('Mark as Watched', style: TextStyle(color: Colors.white)),
                                          onTap: () => Navigator.pop(context),
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.bookmark_border, color: Colors.white54),
                                          title: const Text('Add to Watchlist', style: TextStyle(color: Colors.white)),
                                          onTap: () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              scaleAmount: 0.85,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(100),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.more_vert,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: _buildBadge(movie.rating, const Color(0xFFE50914)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFE50914)),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style:
                              const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: sampleMovies.length,
        itemBuilder: (context, index) {
          final movie = sampleMovies[index];
          return InteractiveCard(
            onTap: () => _openMovie(context, movie),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [movie.gradientStart, movie.gradientEnd],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter_outlined,
                      color: Colors.white.withAlpha(80), size: 32),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      movie.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('★ ${movie.rating}',
                      style:
                          const TextStyle(color: Colors.amber, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
