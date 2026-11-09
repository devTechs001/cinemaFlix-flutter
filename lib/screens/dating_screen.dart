import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../widgets/real_me_bridge.dart';
import '../widgets/cinema_app_bar.dart';

class DatingScreen extends StatefulWidget {
  const DatingScreen({super.key});

  @override
  State<DatingScreen> createState() => _DatingScreenState();
}

class _DatingScreenState extends State<DatingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _genreFilter = 'All';
  int _ageMin = 18;
  int _ageMax = 35;

  final List<String> _genres = ['All', 'Sci-Fi', 'Horror', 'Romance', 'Comedy', 'Action', 'Drama', 'Documentary', 'Anime', 'Thriller', 'Musical'];

  final List<Map<String, dynamic>> _allProfiles = [
    {'name': 'Emma Rivera', 'age': 24, 'bio': 'Horror buff & indie film enthusiast. Nolan is my spirit animal.', 'favoriteMovies': ['The Witch', 'Hereditary', 'Midsommar'], 'color': const Color(0xFF6A1B9A), 'genre': 'Horror', 'distance': '3 km', 'compatibility': 95},
    {'name': 'Liam Chen', 'age': 27, 'bio': 'Marathon runner and Tarantino superfan. Ask me about Kill Bill.', 'favoriteMovies': ['Pulp Fiction', 'Kill Bill Vol. 1', 'Inglourious Basterds'], 'color': const Color(0xFF1565C0), 'genre': 'Action', 'distance': '5 km', 'compatibility': 88},
    {'name': 'Sophia Kim', 'age': 22, 'bio': 'Musical lover & Disney adult. Crying at movies is my hobby.', 'favoriteMovies': ['La La Land', 'The Greatest Showman', 'Coco'], 'color': const Color(0xFFC62828), 'genre': 'Musical', 'distance': '2 km', 'compatibility': 92},
    {'name': 'Marcus Webb', 'age': 29, 'bio': 'Sci-fi nerd and aspiring filmmaker. Villeneuve is the GOAT.', 'favoriteMovies': ['Blade Runner 2049', 'Arrival', 'Dune'], 'color': const Color(0xFF2E7D32), 'genre': 'Sci-Fi', 'distance': '8 km', 'compatibility': 91},
    {'name': 'Aria Patel', 'age': 25, 'bio': 'Documentary junkie. I cry at nature docs. No shame.', 'favoriteMovies': ['My Octopus Teacher', 'Free Solo', 'Planet Earth II'], 'color': const Color(0xFFE65100), 'genre': 'Documentary', 'distance': '4 km', 'compatibility': 85},
    {'name': 'Noah Torres', 'age': 26, 'bio': 'Comedy is my love language. Judd Apatow raised me.', 'favoriteMovies': ['Superbad', 'Step Brothers', 'The 40-Year-Old Virgin'], 'color': const Color(0xFF00838F), 'genre': 'Comedy', 'distance': '6 km', 'compatibility': 79},
    {'name': 'Olivia Brooks', 'age': 23, 'bio': 'Golden Age Hollywood in a Gen Z body. Casablanca forever.', 'favoriteMovies': ['Casablanca', 'Gone with the Wind', 'Sunset Boulevard'], 'color': const Color(0xFF4A148C), 'genre': 'Drama', 'distance': '1 km', 'compatibility': 82},
    {'name': 'Ethan James', 'age': 28, 'bio': 'Action junkie. If it explodes, I\'m watching it.', 'favoriteMovies': ['Mad Max: Fury Road', 'John Wick', 'The Dark Knight'], 'color': const Color(0xFFBF360C), 'genre': 'Action', 'distance': '7 km', 'compatibility': 76},
    {'name': 'Zara Williams', 'age': 24, 'bio': 'Anime marathon queen. Studio Ghibli is my happy place.', 'favoriteMovies': ['Spirited Away', 'Your Name', 'Princess Mononoke'], 'color': const Color(0xFF7B1FA2), 'genre': 'Anime', 'distance': '3 km', 'compatibility': 94},
    {'name': 'Oliver Grant', 'age': 30, 'bio': 'Classic film lover. Hitchcock, Kubrick, Kurosawa.', 'favoriteMovies': ['Psycho', '2001: A Space Odyssey', 'Seven Samurai'], 'color': const Color(0xFF37474F), 'genre': 'Thriller', 'distance': '10 km', 'compatibility': 73},
  ];

  final List<Map<String, dynamic>> _profiles = [];
  final List<Map<String, dynamic>> _matches = [
    {'name': 'Emma Rivera', 'avatar': 'ER', 'color': const Color(0xFF6A1B9A), 'movie': 'Hereditary', 'matched': '2d ago', 'online': true},
    {'name': 'Liam Chen', 'avatar': 'LC', 'color': const Color(0xFF1565C0), 'movie': 'Pulp Fiction', 'matched': '5d ago', 'online': false},
    {'name': 'Sophia Kim', 'avatar': 'SK', 'color': const Color(0xFFC62828), 'movie': 'La La Land', 'matched': '1w ago', 'online': true},
    {'name': 'Marcus Webb', 'avatar': 'MW', 'color': const Color(0xFF2E7D32), 'movie': 'Dune', 'matched': '1w ago', 'online': false},
    {'name': 'Aria Patel', 'avatar': 'AP', 'color': const Color(0xFFE65100), 'movie': 'Free Solo', 'matched': '2w ago', 'online': true},
  ];

  final List<Map<String, dynamic>> _messages = [
    {'name': 'Emma Rivera', 'avatar': 'ER', 'color': const Color(0xFF6A1B9A), 'lastMsg': 'Have you seen The Witch? It\'s so good!', 'time': '5m', 'unread': 2, 'online': true},
    {'name': 'Liam Chen', 'avatar': 'LC', 'color': const Color(0xFF1565C0), 'lastMsg': 'Kill Bill marathon this weekend?', 'time': '1h', 'unread': 0, 'online': false},
    {'name': 'Sophia Kim', 'avatar': 'SK', 'color': const Color(0xFFC62828), 'lastMsg': 'La La Land soundtrack is on repeat 🎵', 'time': '3h', 'unread': 1, 'online': true},
    {'name': 'Marcus Webb', 'avatar': 'MW', 'color': const Color(0xFF2E7D32), 'lastMsg': 'Have you seen the new Dune trailer?', 'time': '1d', 'unread': 0, 'online': false},
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

  void _resetProfiles() {
    setState(() => _profiles.addAll(_allProfiles));
  }

  void _showFilters() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Discovery Filters', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('Preferred Genre', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _genres.map((g) => GestureDetector(
                  onTap: () {
                    setState(() => _genreFilter = g);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _genreFilter == g ? const Color(0xFFE50914) : Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(g, style: TextStyle(color: _genreFilter == g ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Age Range', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 12),
              RangeSlider(
                values: RangeValues(_ageMin.toDouble(), _ageMax.toDouble()),
                min: 18, max: 60,
                divisions: 42,
                activeColor: const Color(0xFFE50914),
                inactiveColor: Colors.white12,
                labels: RangeLabels('$_ageMin', '$_ageMax'),
                onChanged: (v) => setState(() {
                  _ageMin = v.start.toInt();
                  _ageMax = v.end.toInt();
                }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_ageMin', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  Text('$_ageMax', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final currentState = this;
                    currentState.setState(() {});
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Menu',
          onPressed: () => openParentDrawer(context),
          icon: Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.menu, color: Colors.white, size: 20),
          ),
        ),
        title: const Text('Date Night', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(onPressed: _connectRealMe, tooltip: 'Connect to Real Me', icon: const Icon(Icons.favorite, color: Color(0xFFE50914))),
          IconButton(onPressed: _showFilters, icon: const Icon(Icons.tune, color: Colors.white70)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFFE50914),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Discover'),
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Text('${_profiles.length}', style: const TextStyle(fontSize: 10)),
                    ),
                  ],
                )),
                Tab(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_outline, size: 16),
                    const SizedBox(width: 6),
                    const Text('Matches'),
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(80), borderRadius: BorderRadius.circular(8)),
                      child: Text('${_matches.length}', style: const TextStyle(fontSize: 10)),
                    ),
                  ],
                )),
                Tab(child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_outlined, size: 16),
                    const SizedBox(width: 6),
                    const Text('Messages'),
                    if (_messages.where((m) => m['unread'] > 0).isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(8)),
                        child: Text('${_messages.where((m) => m['unread'] > 0).length}', style: const TextStyle(fontSize: 10)),
                      ),
                  ],
                )),
              ],
            ),
          ),
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

  void _connectRealMe() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            const Text('Connect to Real Me', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Mirror Date Night rooms into the real_me companion so matches stay live across both apps.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            const RealMeBridge(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/live');
                  },
                  child: const Text('Open Real Me live rooms', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealMeConnectBar() {
    return InteractiveCard(
      onTap: _connectRealMe,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6C2BD9), Color(0xFFE50914)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connect to Real Me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('Live matches in the companion app', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Find Your Cinema Soulmate', style: TextStyle(fontSize: 12, color: Colors.white54)),
              const Spacer(),
              if (_genreFilter != 'All')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE50914).withAlpha(60)),
                  ),
                  child: Text(_genreFilter, style: const TextStyle(color: Color(0xFFE50914), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _genres.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final g = _genres[index];
                final active = _genreFilter == g;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _genreFilter = g);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE50914) : Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(g, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildRealMeConnectBar(),
          const SizedBox(height: 12),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.white24, size: 56),
                ),
                const SizedBox(height: 20),
                const Text('No more profiles', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  _genreFilter != 'All'
                      ? 'No $_genreFilter fans nearby. Try a different genre.'
                      : 'Check back later for new members!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 24),
                InteractiveCard(
                  onTap: _resetProfiles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
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
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.favorite_border, color: Colors.white24, size: 56),
                ),
                const SizedBox(height: 16),
                const Text('No matches yet', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Keep swiping to find your match!', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFE50914), size: 16),
                      const SizedBox(width: 8),
                      Text('${_matches.length} matches', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      const Spacer(),
                      Text('Online now: ${_matches.where((m) => m['online'] == true).length}', style: const TextStyle(color: Color(0xFF43A047), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
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
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: (match['color'] as Color).withAlpha(40),
                                    child: Text(match['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                  ),
                                  if (match['online'] == true)
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 14, height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF43A047),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFF1F1F1F), width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(match['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text('Matched on ${match['movie']}', style: const TextStyle(color: Colors.white38, fontSize: 10), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(match['matched'], style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildMessagesTab() {
    return _messages.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 56),
                ),
                const SizedBox(height: 16),
                const Text('No messages yet', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Match with someone to start chatting', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final unread = msg['unread'] as int;
              final online = msg['online'] as bool;
              return InteractiveCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening chat with ${msg['name']}...'),
                      backgroundColor: const Color(0xFFE50914),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: (msg['color'] as Color).withAlpha(40),
                            child: Text(msg['avatar'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (online)
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43A047),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF141414), width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(msg['name'], style: TextStyle(color: Colors.white, fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500, fontSize: 15)),
                                const SizedBox(width: 8),
                                if (unread > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE50914),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['lastMsg'],
                              style: TextStyle(
                                color: unread > 0 ? Colors.white70 : Colors.white38,
                                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(msg['time'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 4),
                          if (unread > 0)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE50914),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
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
                          (widget.profile['color'] as Color).withAlpha(60),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text('${widget.profile['compatibility']}% match', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
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
                          color: isRight ? const Color(0xFF43A047).withAlpha(220) : const Color(0xFFE50914).withAlpha(220),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isRight ? const Color(0xFF43A047) : const Color(0xFFE50914), width: 2),
                        ),
                        child: Text(
                          isRight ? 'LIKE' : 'PASS',
                          style: const TextStyle(
                            color: Colors.white,
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
                            Text(widget.profile['name'], style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text('${widget.profile['age']}', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 22, fontWeight: FontWeight.w300)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                              child: Text(widget.profile['distance'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(widget.profile['bio'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Favorite Movies', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            const SizedBox(width: 8),
                            Icon(Icons.movie_outlined, color: Colors.white.withAlpha(40), size: 14),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6, runSpacing: 4,
                          children: (widget.profile['favoriteMovies'] as List<String>).map((m) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                              child: Text(m, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
                                width: 56, height: 56,
                                decoration: BoxDecoration(color: const Color(0xFF2A2A2A), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE50914), width: 2)),
                                child: const Icon(Icons.close, color: Color(0xFFE50914), size: 28),
                              ),
                            ),
                            const SizedBox(width: 22),
                            InteractiveCard(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                widget.onLike();
                              },
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A237E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF82B1FF), width: 2),
                                ),
                                child: const Icon(Icons.star, color: Color(0xFF82B1FF), size: 22),
                              ),
                            ),
                            const SizedBox(width: 22),
                            InteractiveCard(
                              onTap: widget.onLike,
                              child: Container(
                                width: 56, height: 56,
                                decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
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
