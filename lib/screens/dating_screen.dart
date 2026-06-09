import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';

class DatingScreen extends StatefulWidget {
  const DatingScreen({super.key});

  @override
  State<DatingScreen> createState() => _DatingScreenState();
}

class _DatingScreenState extends State<DatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _allProfiles = [
    {
      'name': 'Emma Rivera',
      'age': 24,
      'bio': 'Horror buff & indie film enthusiast. Nolan is my spirit animal.',
      'favoriteMovies': ['The Witch', 'Hereditary', 'Midsommar'],
      'color': const Color(0xFF6A1B9A),
    },
    {
      'name': 'Liam Chen',
      'age': 27,
      'bio': 'Marathon runner and Tarantino superfan. Ask me about Kill Bill.',
      'favoriteMovies': ['Pulp Fiction', 'Kill Bill Vol. 1', 'Inglourious Basterds'],
      'color': const Color(0xFF1565C0),
    },
    {
      'name': 'Sophia Kim',
      'age': 22,
      'bio': 'Musical lover & Disney adult. Crying at movies is my hobby.',
      'favoriteMovies': ['La La Land', 'The Greatest Showman', 'Coco'],
      'color': const Color(0xFFC62828),
    },
    {
      'name': 'Marcus Webb',
      'age': 29,
      'bio': 'Sci-fi nerd and aspiring filmmaker. Villeneuve is the GOAT.',
      'favoriteMovies': ['Blade Runner 2049', 'Arrival', 'Dune'],
      'color': const Color(0xFF2E7D32),
    },
    {
      'name': 'Aria Patel',
      'age': 25,
      'bio': 'Documentary junkie. I cry at nature docs. No shame.',
      'favoriteMovies': ['My Octopus Teacher', 'Free Solo', 'Planet Earth II'],
      'color': const Color(0xFFE65100),
    },
    {
      'name': 'Noah Torres',
      'age': 26,
      'bio': 'Comedy is my love language. Judd Apatow raised me.',
      'favoriteMovies': ['Superbad', 'Step Brothers', 'The 40-Year-Old Virgin'],
      'color': const Color(0xFF00838F),
    },
    {
      'name': 'Olivia Brooks',
      'age': 23,
      'bio': 'Golden Age Hollywood in a Gen Z body. Casablanca forever.',
      'favoriteMovies': ['Casablanca', 'Gone with the Wind', 'Sunset Boulevard'],
      'color': const Color(0xFF4A148C),
    },
    {
      'name': 'Ethan James',
      'age': 28,
      'bio': 'Action junkie. If it explodes, I\'m watching it.',
      'favoriteMovies': ['Mad Max: Fury Road', 'John Wick', 'The Dark Knight'],
      'color': const Color(0xFFBF360C),
    },
  ];

  final List<Map<String, dynamic>> _profiles = [];
  final List<Map<String, dynamic>> _matches = [
    {'name': 'Emma Rivera', 'avatar': 'ER', 'color': const Color(0xFF6A1B9A), 'movie': 'Hereditary'},
    {'name': 'Liam Chen', 'avatar': 'LC', 'color': const Color(0xFF1565C0), 'movie': 'Pulp Fiction'},
    {'name': 'Sophia Kim', 'avatar': 'SK', 'color': const Color(0xFFC62828), 'movie': 'La La Land'},
  ];

  final List<Map<String, dynamic>> _messages = [
    {'name': 'Emma Rivera', 'avatar': 'ER', 'color': const Color(0xFF6A1B9A), 'lastMsg': 'Have you seen The Witch? It\'s so good!', 'time': '5m', 'unread': 2},
    {'name': 'Liam Chen', 'avatar': 'LC', 'color': const Color(0xFF1565C0), 'lastMsg': 'Kill Bill marathon this weekend?', 'time': '1h', 'unread': 0},
    {'name': 'Sophia Kim', 'avatar': 'SK', 'color': const Color(0xFFC62828), 'lastMsg': 'La La Land soundtrack is on repeat', 'time': '3h', 'unread': 1},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _profiles.addAll(_allProfiles);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Date Night', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE50914),
          labelColor: const Color(0xFFE50914),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'Matches'),
            Tab(text: 'Messages'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDiscoverTab(),
          _buildMatchesTab(),
          _buildMessagesTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find Your Cinema Soulmate',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildSwipeStack()),
        ],
      ),
    );
  }

  Widget _buildSwipeStack() {
    return Stack(
      children: [
        if (_profiles.isNotEmpty)
          for (int i = _profiles.length - 1; i >= 0; i--)
            _SwipeCard(
              key: ValueKey(_profiles[i]['name']),
              profile: _profiles[i],
              stackIndex: _profiles.length - 1 - i,
              onLike: () {
                HapticFeedback.lightImpact();
                setState(() {
                  final profile = _profiles.removeAt(0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('You liked ${profile['name']}!'),
                      backgroundColor: const Color(0xFFE50914),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                });
              },
              onPass: () {
                HapticFeedback.mediumImpact();
                setState(() => _profiles.removeAt(0));
              },
            ),
        if (_profiles.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'No more profiles',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 8),
                InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _profiles.addAll(_allProfiles));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMatchesTab() {
    return _matches.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, color: Colors.white24, size: 64),
                SizedBox(height: 16),
                Text('No matches yet', style: TextStyle(color: Colors.white54, fontSize: 18)),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _tabController.animateTo(2);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: (match['color'] as Color).withAlpha(40),
                          child: Text(
                            match['avatar'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          match['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Matched on ${match['movie']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
  }

  Widget _buildMessagesTab() {
    return _messages.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 64),
                SizedBox(height: 16),
                Text('No messages yet', style: TextStyle(color: Colors.white54, fontSize: 18)),
              ],
            ),
          )
        : ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _messages.length,
            separatorBuilder: (_, _) =>
                const Divider(color: Color(0xFF2A2A2A), height: 1, indent: 76),
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return InteractiveCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening chat with ${msg['name']}...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: (msg['color'] as Color).withAlpha(40),
                    child: Text(
                      msg['avatar'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        msg['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (msg['unread'] > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${msg['unread']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    msg['lastMsg'],
                    style: const TextStyle(color: Colors.white54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    msg['time'],
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              );
            },
          );
  }
}

class _SwipeCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final int stackIndex;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const _SwipeCard({
    super.key,
    required this.profile,
    required this.stackIndex,
    required this.onLike,
    required this.onPass,
  });

  @override
  State<_SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<_SwipeCard> {
  double _dragX = 0;
  double _dragY = 0;

  static const double _swipeThreshold = 120;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragX += details.delta.dx;
      _dragY += details.delta.dy;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragX.abs() > _swipeThreshold) {
      if (_dragX > 0) {
        widget.onLike();
      } else {
        widget.onPass();
      }
    }
    setState(() {
      _dragX = 0;
      _dragY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTop = widget.stackIndex == 0;

    if (!isTop && widget.stackIndex < 4) {
      final inset = 4.0 * widget.stackIndex;
      return Positioned(
        top: inset,
        left: inset,
        right: inset,
        bottom: 0,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
        ),
      );
    }

    if (!isTop) return const SizedBox.shrink();

    final opacity = (_dragX.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final isRight = _dragX > 0;
    final angle = _dragX * 0.05;

    return Positioned.fill(
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform.translate(
          offset: Offset(_dragX, _dragY),
          child: Transform.rotate(
            angle: angle * 0.0174533,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (widget.profile['color'] as Color).withAlpha(200),
                          (widget.profile['color'] as Color).withAlpha(80),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  if (opacity > 0.2)
                    Positioned(
                      top: 32,
                      left: isRight ? 24 : null,
                      right: isRight ? null : 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isRight
                              ? const Color(0xFF43A047).withAlpha(220)
                              : const Color(0xFFE50914).withAlpha(220),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isRight
                                ? const Color(0xFF43A047)
                                : const Color(0xFFE50914),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          isRight ? 'LIKE' : 'PASS',
                          style: TextStyle(
                            color: isRight
                                ? const Color(0xFF43A047)
                                : const Color(0xFFE50914),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              widget.profile['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.profile['age']}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 22,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.profile['bio'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Favorite Movies',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children:
                              (widget.profile['favoriteMovies'] as List<String>).map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m,
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InteractiveCard(
                              onTap: widget.onPass,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE50914), width: 2),
                                ),
                                child: const Icon(Icons.close, color: Color(0xFFE50914), size: 28),
                              ),
                            ),
                            const SizedBox(width: 40),
                            InteractiveCard(
                              onTap: widget.onLike,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE50914),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.favorite, color: Colors.white, size: 28),
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
          ),
        ),
      ),
    );
  }
}
