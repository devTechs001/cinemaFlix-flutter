import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _liked = {};
  final Set<String> _bookmarked = {};

  final List<_ShortItem> _shorts = [
    _ShortItem(movie: sampleMovies[0], description: 'The sandworm scene from Dune: Part Two — absolutely breathtaking! #Dune #SciFi', likes: 12453, comments: 847, shares: 2314),
    _ShortItem(movie: sampleMovies[1], description: 'Oppenheimer\'s Trinity test — one of the most powerful scenes in cinema history. #Oppenheimer #Nolan', likes: 9876, comments: 654, shares: 1876),
    _ShortItem(movie: sampleMovies[2], description: 'The Batmobile chase through Gotham — pure cinematic excellence! #TheBatman #DC', likes: 7654, comments: 432, shares: 1543),
    _ShortItem(movie: sampleMovies[4], description: 'Furiosa: The beginning of a legend. George Miller does it again! #Furiosa #MadMax', likes: 5432, comments: 321, shares: 987),
    _ShortItem(movie: sampleMovies[6], description: 'Interstellar\'s docking scene — still gives us chills. #Interstellar #Nolan', likes: 11234, comments: 789, shares: 2567),
    _ShortItem(movie: sampleMovies[3], description: 'Deadpool breaks the fourth wall... again! 🤣 #Deadpool #Marvel', likes: 8765, comments: 567, shares: 1987),
    _ShortItem(movie: sampleMovies[5], description: 'Inception\'s hallway fight — a masterpiece of practical effects. #Inception #Nolan', likes: 6789, comments: 456, shares: 1234),
    _ShortItem(movie: sampleMovies[7], description: 'Joker\'s stair dance — an iconic moment in film history. #Joker #DC', likes: 9876, comments: 654, shares: 2345),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}k';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _shorts.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final short = _shorts[index];
              final isLiked = _liked.contains(short.movie.id);
              final isBookmarked = _bookmarked.contains(short.movie.id);

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [short.movie.gradientStart, short.movie.gradientEnd],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.play_circle_fill, color: Colors.white54, size: 56),
                          ),
                          const SizedBox(height: 16),
                          Text(short.movie.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('★ ${short.movie.rating}', style: const TextStyle(color: Colors.amber, fontSize: 16)),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 100,
                      left: 16,
                      right: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFE50914),
                                child: const Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              const Text('CinemaFlix', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(width: 8),
                              InteractiveCard(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Following CinemaFlix'), duration: Duration(seconds: 1)),
                                  );
                                },
                                child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(short.description, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.music_note, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(short.movie.genre, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 100,
                      right: 12,
                      child: Column(
                        children: [
                          _actionColumn(Icons.favorite, Icons.favorite_border, isLiked, _formatCount(short.likes), () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isLiked) { _liked.remove(short.movie.id); } else { _liked.add(short.movie.id); }
                            });
                          }),
                          const SizedBox(height: 16),
                          _actionColumn(Icons.chat_bubble, Icons.chat_bubble_outline, false, _formatCount(short.comments), () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Comments coming soon'), duration: Duration(seconds: 1)),
                            );
                          }),
                          const SizedBox(height: 16),
                          _actionColumn(Icons.bookmark, Icons.bookmark_border, isBookmarked, '', () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              if (isBookmarked) { _bookmarked.remove(short.movie.id); } else { _bookmarked.add(short.movie.id); }
                            });
                          }),
                          const SizedBox(height: 16),
                          _actionColumn(Icons.share, Icons.share_outlined, false, _formatCount(short.shares), () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Share ${short.movie.title}'), duration: const Duration(seconds: 1)),
                            );
                          }),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_shorts.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: _currentPage == i ? 20 : 6,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _currentPage == i ? const Color(0xFFE50914) : Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Top Tabs
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _topTab('Following', false),
                const SizedBox(width: 20),
                _topTab('For You', true),
              ],
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 10,
                top: 15,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(200)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.home_filled, 'Home', false, () => Navigator.pushReplacementNamed(context, '/main')),
                  _navItem(Icons.explore, 'Explore', false, () => Navigator.pushReplacementNamed(context, '/main')),
                  _addShortButton(),
                  _navItem(Icons.chat_bubble, 'Inbox', false, () => Navigator.pushReplacementNamed(context, '/main')),
                  _navItem(Icons.person, 'Profile', false, () => Navigator.pushReplacementNamed(context, '/main')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topTab(String label, bool active) {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 24,
              height: 2,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _addShortButton() {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload short coming soon'), duration: Duration(seconds: 1)),
        );
      },
      scaleAmount: 0.9,
      child: Container(
        width: 45,
        height: 30,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF20D5EC),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0050),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 38,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionColumn(IconData filled, IconData outlined, bool active, String label, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.85,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              active ? filled : outlined,
              color: active ? const Color(0xFFE50914) : Colors.white,
              size: 24,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.9,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ShortItem {
  final SampleMovie movie;
  final String description;
  final int likes;
  final int comments;
  final int shares;

  const _ShortItem({
    required this.movie,
    required this.description,
    required this.likes,
    required this.comments,
    required this.shares,
  });
}
