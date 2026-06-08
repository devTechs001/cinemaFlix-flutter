import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sample_movies.dart';
import '../widgets/interactive_card.dart';
import 'movie_play_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final SampleMovie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  double _userRating = 0;
  bool _isFavorited = false;
  bool _inWatchlist = false;

  final List<Map<String, dynamic>> _sampleComments = const [
    {'user': 'Sarah J.', 'avatar': 'S', 'comment': 'Absolutely stunning cinematography! The visual effects were mind-blowing. A must-watch for any sci-fi fan.', 'rating': 5, 'time': '2h ago', 'likes': 24},
    {'user': 'Mike Chen', 'avatar': 'M', 'comment': 'The storyline kept me on the edge of my seat. One of the best movies this year!', 'rating': 4, 'time': '5h ago', 'likes': 18},
    {'user': 'Emma W.', 'avatar': 'E', 'comment': 'Great performances by the cast. The director really outdid themselves with this one.', 'rating': 5, 'time': '1d ago', 'likes': 31},
    {'user': 'Alex Turner', 'avatar': 'A', 'comment': 'I watched it twice already. Each time I notice something new. Brilliant filmmaking.', 'rating': 4, 'time': '2d ago', 'likes': 12},
    {'user': 'Rachel Kim', 'avatar': 'R', 'comment': 'Good movie but the pacing was a bit slow in the middle. The ending made up for it though.', 'rating': 3, 'time': '3d ago', 'likes': 7},
  ];

  @override
  void initState() {
    super.initState();
    _comments.addAll(_sampleComments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _comments.insert(0, {
        'user': 'You',
        'avatar': 'Y',
        'comment': text,
        'rating': _userRating,
        'time': 'just now',
        'likes': 0,
      });
    });
    _commentController.clear();
    _userRating = 0;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review added!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: const Color(0xFF141414),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.movie.gradientStart,
                      widget.movie.gradientEnd,
                      const Color(0xFF141414),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.movie_filter_outlined, color: Colors.white.withAlpha(30), size: 120),
                    ),
                    Positioned(
                      bottom: 40, left: 20, right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.movie.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _badge(widget.movie.rating, const Color(0xFFE50914)),
                              const SizedBox(width: 10),
                              Text(widget.movie.year, style: const TextStyle(color: Colors.white54)),
                              const SizedBox(width: 10),
                              const Icon(Icons.circle, size: 4, color: Colors.white38),
                              const SizedBox(width: 10),
                              Text(widget.movie.duration, style: const TextStyle(color: Colors.white54)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(widget.movie.genre, style: const TextStyle(color: Color(0xFFE50914), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InteractiveCard(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, a1, a2) => MoviePlayScreen(movie: widget.movie),
                                transitionsBuilder: (context, anim, secondary, child) => FadeTransition(opacity: anim, child: child),
                                transitionDuration: const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE50914),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text('Play Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _actionButton(Icons.bookmark_border, Icons.bookmark, _inWatchlist, () {
                        HapticFeedback.lightImpact();
                        setState(() => _inWatchlist = !_inWatchlist);
                      }),
                      const SizedBox(width: 12),
                      _actionButton(Icons.favorite_border, Icons.favorite, _isFavorited, () {
                        HapticFeedback.lightImpact();
                        setState(() => _isFavorited = !_isFavorited);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(widget.movie.description, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 20),
                  _infoRow('Director', widget.movie.director),
                  const SizedBox(height: 8),
                  _infoRow('Cast', widget.movie.cast),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFF2A2A2A)),
                  const SizedBox(height: 16),
                  _buildRatingSection(),
                  const SizedBox(height: 20),
                  _buildCommentInput(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${_comments.length} reviews', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._comments.asMap().entries.map((e) => _buildCommentCard(e.value, e.key)),
                  const SizedBox(height: 24),
                  _buildMoreLikeThis(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData outlined, IconData filled, bool isActive, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.85,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? const Color(0xFFE50914) : Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(isActive ? filled : outlined, color: isActive ? const Color(0xFFE50914) : Colors.white54),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rate This Movie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            final star = i + 1;
            return InteractiveCard(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _userRating = _userRating == star ? 0 : star.toDouble());
              },
              scaleAmount: 0.85,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  star <= _userRating ? Icons.star : Icons.star_border,
                  color: star <= _userRating ? Colors.amber : Colors.white24,
                  size: 36,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _commentController,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Write your review...',
              hintStyle: const TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InteractiveCard(
              onTap: _addComment,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _commentController.text.trim().isEmpty ? Colors.white12 : const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> comment, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2A2A2A),
                child: Text(comment['avatar'], style: const TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment['user'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < (comment['rating'] as int) ? Icons.star : Icons.star_border,
                          color: Colors.amber, size: 12,
                        )),
                        const SizedBox(width: 6),
                        Text(comment['time'], style: const TextStyle(color: Colors.white24, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              InteractiveCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => comment['likes'] = (comment['likes'] as int) + 1);
                },
                scaleAmount: 0.85,
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.white38, size: 16),
                    const SizedBox(width: 4),
                    Text('${comment['likes']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment['comment'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildMoreLikeThis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('More Like This', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sampleMovies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final related = sampleMovies[i];
              if (related.id == widget.movie.id) return const SizedBox.shrink();
              return InteractiveCard(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, a1, a2) => MovieDetailScreen(movie: related),
                      transitionsBuilder: (context, anim, secondary, child) => FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [related.gradientStart, related.gradientEnd]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined, color: const Color(0xFFE50914).withAlpha(120), size: 32),
                      const SizedBox(height: 8),
                      Text(related.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('★ ${related.rating}', style: const TextStyle(color: Colors.amber, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14))),
      ],
    );
  }
}
