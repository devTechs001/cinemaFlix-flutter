import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/globals.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<SampleMovie> _results = [];
  bool _isSearching = false;
  final Set<String> _watchlist = {};

  String get _userId => authService.currentUser?.id ?? guestService.guestId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _results = [];
      } else {
        _results = sampleMovies
            .where((m) =>
                m.title.toLowerCase().contains(query.toLowerCase()) ||
                m.genre.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _openMovie(BuildContext context, SampleMovie movie) {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/movie-detail', arguments: movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search movies, genres...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : InteractiveCard(
                        onTap: () => HapticFeedback.lightImpact(),
                        child: const Icon(Icons.filter_list, color: Colors.white54),
                      ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_isSearching && _results.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.white.withAlpha(40)),
                    const SizedBox(height: 16),
                    const Text('No movies found',
                        style: TextStyle(color: Colors.white38, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Try a different search term',
                        style: TextStyle(color: Colors.white24, fontSize: 13)),
                  ],
                ),
              ),
            )
          else if (_isSearching)
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(
                    color: Color(0xFF2A2A2A), height: 1, indent: 76),
                itemBuilder: (context, index) {
                  final movie = _results[index];
                  return InteractiveCard(
                    onTap: () => _openMovie(context, movie),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [movie.gradientStart, movie.gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.movie_outlined,
                            color: Colors.white54, size: 22),
                      ),
                      title: Text(movie.title,
                          style:
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${movie.genre} • ★ ${movie.rating}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: InteractiveCard(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final isWatch = _watchlist.contains(movie.id);
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
                        scaleAmount: 0.85,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _watchlist.contains(movie.id) ? Icons.bookmark : Icons.bookmark_border,
                              color: _watchlist.contains(movie.id) ? const Color(0xFFE50914) : Colors.white38, size: 18),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Popular Searches',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sampleMovies.take(6).map((movie) {
                      return InteractiveCard(
                        onTap: () => _openMovie(context, movie),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.trending_up,
                                  color: Color(0xFFE50914), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                movie.title,
                                style:
                                    const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
