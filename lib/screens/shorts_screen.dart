import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';

class ShortsScreen extends StatefulWidget {
  const ShortsScreen({super.key});

  @override
  State<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _liked = {};
  final Set<String> _bookmarked = {};
  bool _isLoading = true;

  late AnimationController _heartBurstController;
  late Animation<double> _heartBurstScale;
  late Animation<double> _heartBurstOpacity;

  late AnimationController _musicPulseController;
  late AnimationController _discSpinController;

  final Map<int, AnimationController> _likePulseControllers = {};
  final Map<int, AnimationController> _playPauseControllers = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, AnimationController> _followControllers = {};

  final List<_ShortItem> _shorts = [
    _ShortItem(movie: sampleMovies[0], description: 'The sandworm scene from Dune: Part Two \u2014 absolutely breathtaking! #Dune #SciFi', likes: 12453, comments: 847, shares: 2314),
    _ShortItem(movie: sampleMovies[1], description: 'Oppenheimer\'s Trinity test \u2014 one of the most powerful scenes in cinema history. #Oppenheimer #Nolan', likes: 9876, comments: 654, shares: 1876),
    _ShortItem(movie: sampleMovies[2], description: 'The Batmobile chase through Gotham \u2014 pure cinematic excellence! #TheBatman #DC', likes: 7654, comments: 432, shares: 1543),
    _ShortItem(movie: sampleMovies[4], description: 'Furiosa: The beginning of a legend. George Miller does it again! #Furiosa #MadMax', likes: 5432, comments: 321, shares: 987),
    _ShortItem(movie: sampleMovies[6], description: 'Interstellar\'s docking scene \u2014 still gives us chills. #Interstellar #Nolan', likes: 11234, comments: 789, shares: 2567),
    _ShortItem(movie: sampleMovies[3], description: 'Deadpool breaks the fourth wall... again! \ud83e\udd23 #Deadpool #Marvel', likes: 8765, comments: 567, shares: 1987),
    _ShortItem(movie: sampleMovies[5], description: 'Inception\'s hallway fight \u2014 a masterpiece of practical effects. #Inception #Nolan', likes: 6789, comments: 456, shares: 1234),
    _ShortItem(movie: sampleMovies[7], description: 'Joker\'s stair dance \u2014 an iconic moment in film history. #Joker #DC', likes: 9876, comments: 654, shares: 2345),
  ];

  @override
  void initState() {
    super.initState();
    _heartBurstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heartBurstScale = Tween<double>(begin: 0.0, end: 1.3).animate(CurvedAnimation(parent: _heartBurstController, curve: Curves.elasticOut));
    _heartBurstOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _heartBurstController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _musicPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _discSpinController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    for (var i = 0; i < _shorts.length; i++) {
      _isPlaying[i] = true;
      _likePulseControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
      _playPauseControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
      _followControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartBurstController.dispose();
    _musicPulseController.dispose();
    _discSpinController.dispose();
    for (final c in _likePulseControllers.values) c.dispose();
    for (final c in _playPauseControllers.values) c.dispose();
    for (final c in _followControllers.values) c.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}k';
    return count.toString();
  }

  void _toggleLike(int index) {
    final id = _shorts[index].movie.id;
    HapticFeedback.lightImpact();
    setState(() {
      if (_liked.contains(id)) _liked.remove(id);
      else _liked.add(id);
    });
    _likePulseControllers[index]?.forward().then((_) => _likePulseControllers[index]?.reverse());
  }

  void _handleDoubleTapLike(int index) {
    final id = _shorts[index].movie.id;
    setState(() => _liked.add(id));
    _heartBurstController.forward(from: 0);
    HapticFeedback.heavyImpact();
    _likePulseControllers[index]?.forward().then((_) => _likePulseControllers[index]?.reverse());
  }

  void _togglePlayPause(int index) {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying[index] = !(_isPlaying[index] ?? true));
    _playPauseControllers[index]?.forward(from: 0);
  }

  void _showCommentsSheet(BuildContext context, _ShortItem short) {
    final comments = List<Map<String, dynamic>>.generate(5, (i) => {
      'user': ['Sarah J.', 'Mike C.', 'Emma W.', 'Alex T.', 'Rachel K.'][i],
      'avatar': ['SJ', 'MC', 'EW', 'AT', 'RK'][i],
      'text': ['This is absolutely incredible! \ud83d\udd25', 'The visuals are stunning \ud83d\ude0d', 'Can\'t stop watching this!', 'Best short on CinemaFlix!', 'More content like this please \ud83d\ude4f'][i],
      'time': '${i + 1}h ago',
      'likes': [12, 8, 5, 3, 1][i],
      'liked': false,
    });
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: const EdgeInsets.only(top: 8), width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Comments (${short.comments})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    InteractiveCard(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Colors.white38, size: 20)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAvatar(radius: 16, backgroundColor: const Color(0xFF2A2A2A), child: Text(c['avatar'], style: const TextStyle(color: Color(0xFFE50914), fontSize: 10, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Text(c['user'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(width: 6), Text(c['time'], style: const TextStyle(color: Colors.white24, fontSize: 10))]),
                          const SizedBox(height: 4), Text(c['text'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(children: [
                            InteractiveCard(onTap: () => setSheetState(() { c['liked'] = !c['liked']; c['likes'] += c['liked'] ? 1 : -1; }), child: Row(children: [Icon(c['liked'] ? Icons.favorite : Icons.favorite_border, color: c['liked'] ? const Color(0xFFE50914) : Colors.white38, size: 14), const SizedBox(width: 4), Text('${c['likes']}', style: TextStyle(color: c['liked'] ? const Color(0xFFE50914) : Colors.white38, fontSize: 11))])),
                            const SizedBox(width: 12), const Icon(Icons.reply, color: Colors.white24, size: 14), const SizedBox(width: 4), const Text('Reply', style: TextStyle(color: Colors.white24, fontSize: 11)),
                          ]),
                        ])),
                      ]),
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(children: [
                  Expanded(child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(hintText: 'Add a comment...', hintStyle: const TextStyle(color: Colors.white38), filled: true, fillColor: const Color(0xFF2A2A2A), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                    style: const TextStyle(color: Colors.white, fontSize: 13), textInputAction: TextInputAction.send,
                    onSubmitted: (value) { if (value.trim().isEmpty) return; setSheetState(() { comments.insert(0, {'user': 'You', 'avatar': 'YO', 'text': value.trim(), 'time': 'just now', 'likes': 0, 'liked': false}); }); commentController.clear(); HapticFeedback.lightImpact(); },
                  )),
                  const SizedBox(width: 8),
                  InteractiveCard(
                    onTap: () { final value = commentController.text.trim(); if (value.isEmpty) return; setSheetState(() { comments.insert(0, {'user': 'You', 'avatar': 'YO', 'text': value, 'time': 'just now', 'likes': 0, 'liked': false}); }); commentController.clear(); HapticFeedback.lightImpact(); },
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 16)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShareSheet(_ShortItem short) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Share', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(Icons.share, 'Share', Colors.blue),
                  _shareOption(Icons.link, 'Copy Link', Colors.teal),
                  _shareOption(Icons.whatshot, 'WhatsApp', const Color(0xFF25D366)),
                  _shareOption(Icons.message, 'Message', const Color(0xFFE50914)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(Icons.facebook, 'Facebook', const Color(0xFF1877F2)),
                  _shareOption(Icons.tag, 'Twitter', const Color(0xFF1DA1F2)),
                  _shareOption(Icons.sms, 'SMS', const Color(0xFF10B981)),
                  _shareOption(Icons.more_horiz, 'More', Colors.white38),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOption(IconData icon, String label, Color color) {
    return InteractiveCard(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share via $label'), duration: const Duration(seconds: 1)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  void _navigateTo(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: _isLoading ? _buildShimmer() : Stack(
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
              final playing = _isPlaying[index] ?? true;
              final followCtrl = _followControllers[index];

              return GestureDetector(
                onTap: () => _togglePlayPause(index),
                onDoubleTap: () => _handleDoubleTapLike(index),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [short.movie.gradientStart, short.movie.gradientEnd]),
                  ),
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: playing ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 200),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.play_circle_fill, color: Colors.white54, size: 56)),
                              const SizedBox(height: 16),
                              Text(short.movie.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('\u2605 ${short.movie.rating}', style: const TextStyle(color: Colors.amber, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      if (!playing)
                        Center(
                          child: ScaleTransition(
                            scale: _playPauseControllers[index]!,
                            child: Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.black.withAlpha(120), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 40)),
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _heartBurstController,
                        builder: (context, child) => Opacity(
                          opacity: _heartBurstOpacity.value,
                          child: Transform.scale(scale: _heartBurstScale.value, child: child),
                        ),
                        child: const Center(
                          child: Icon(Icons.favorite, color: Colors.white, size: 120, shadows: [Shadow(color: Color(0xFFE50914), blurRadius: 30)]),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.transparent, Colors.black.withAlpha(180)],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 80,
                        bottom: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE50914), child: const Icon(Icons.person, color: Colors.white, size: 22)),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CinemaFlix', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
                                    Text('12.4K followers', style: TextStyle(color: Colors.white60, fontSize: 11, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Following CinemaFlix'), duration: Duration(seconds: 1)),
                                    );
                                    followCtrl?.forward().then((_) => followCtrl.reverse());
                                  },
                                  child: ScaleTransition(
                                    scale: followCtrl ?? AlwaysStoppedAnimation(1.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE50914),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [BoxShadow(color: const Color(0xFFE50914).withAlpha(80), blurRadius: 8)],
                                      ),
                                      child: const Text('Follow', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              short.description,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, shadows: [Shadow(color: Colors.black54, blurRadius: 8)]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _discSpinController,
                                  builder: (context, child) => Transform.rotate(
                                    angle: _discSpinController.value * 6.28,
                                    child: Container(
                                      width: 24, height: 24,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(30), border: Border.all(color: Colors.white38, width: 1.5)),
                                      child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _soundWaveBars(),
                                const SizedBox(width: 8),
                                Text(short.movie.genre, style: const TextStyle(color: Colors.white54, fontSize: 12, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 130,
                        child: Column(
                          children: [
                            _actionColumn(Icons.favorite, Icons.favorite_border, isLiked, _formatCount(short.likes), () => _toggleLike(index), likePulse: _likePulseControllers[index]),
                            const SizedBox(height: 20),
                            _actionColumn(Icons.chat_bubble, Icons.chat_bubble_outline, false, _formatCount(short.comments), () { HapticFeedback.lightImpact(); _showCommentsSheet(context, short); }),
                            const SizedBox(height: 20),
                            _actionColumn(Icons.bookmark, Icons.bookmark_border, isBookmarked, '', () { HapticFeedback.lightImpact(); setState(() { if (isBookmarked) _bookmarked.remove(short.movie.id); else _bookmarked.add(short.movie.id); }); }),
                            const SizedBox(height: 20),
                            _actionColumn(Icons.share, Icons.share_outlined, false, _formatCount(short.shares), () => _showShareSheet(short)),
                            const SizedBox(height: 20),
                            _recordDisc(),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_shorts.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: _currentPage == i ? 20 : 6,
                              height: 3,
                              decoration: BoxDecoration(color: _currentPage == i ? const Color(0xFFE50914) : Colors.white30, borderRadius: BorderRadius.circular(2)),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0, right: 0,
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
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: bottomPadding + 4, top: 8),
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(220)])),
              child: _buildBottomNav(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      color: const Color(0xFF141414),
      child: Column(
        children: [
          const Spacer(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3, valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)), backgroundColor: Colors.white.withAlpha(20))),
                const SizedBox(height: 20),
                Text('Loading shorts...', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14)),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _soundWaveBars() {
    return AnimatedBuilder(
      animation: _musicPulseController,
      builder: (context, child) {
        return SizedBox(
          height: 14, width: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final delay = i * 0.12;
              var value = (_musicPulseController.value + delay) % 1.0;
              value = value < 0.5 ? value * 2 : (1 - value) * 2;
              final h = (4 + value * 10).clamp(0.0, 14.0);
              return Container(width: 3, height: h, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5), boxShadow: [BoxShadow(color: const Color(0xFFE50914).withAlpha(40), blurRadius: 4)]));
            }),
          ),
        );
      },
    );
  }

  Widget _recordDisc() {
    return AnimatedBuilder(
      animation: _discSpinController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _discSpinController.value * 6.28,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(colors: [Color(0xFF2A2A2A), Color(0xFF555555), Color(0xFF2A2A2A), Color(0xFF444444), Color(0xFF2A2A2A)]),
              border: Border.all(color: Colors.white.withAlpha(30), width: 1),
            ),
            child: Center(
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE50914), border: Border.all(color: Colors.white54, width: 1.5)),
                child: const Center(child: Icon(Icons.music_note, color: Colors.white, size: 7)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navItem(Icons.home_filled, 'Home', false, () => _navigateTo('/main')),
        _navItem(Icons.search, 'Explore', false, () => _navigateTo('/explore')),
        _uploadNavButton(),
        _navItem(Icons.mail_outline, 'Inbox', false, () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inbox coming soon'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating),
          );
        }),
        _navItem(Icons.person, 'Profile', false, () => _navigateTo('/main')),
      ],
    );
  }

  Widget _topTab(String label, bool active) {
    return InteractiveCard(
      onTap: () => HapticFeedback.lightImpact(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: active ? FontWeight.bold : FontWeight.w500, fontSize: 16, shadows: active ? [const Shadow(color: Colors.black54, blurRadius: 6)] : null)),
          if (active) Container(margin: const EdgeInsets.only(top: 4), width: 24, height: 2, color: Colors.white),
        ],
      ),
    );
  }

  Widget _uploadNavButton() {
    return InteractiveCard(
      onTap: () {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload Video'), duration: Duration(seconds: 1)),
        );
      },
      scaleAmount: 0.93,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 2),
            const Text('Upload', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _actionColumn(IconData filled, IconData outlined, bool active, String label, VoidCallback onTap, {AnimationController? likePulse}) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.85,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: likePulse ?? AlwaysStoppedAnimation(0),
            builder: (context, child) {
              double scale = 1.0;
              if (likePulse != null && likePulse.isAnimating) scale = 1.0 + likePulse.value * 0.3;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(70), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8)]),
                  child: Icon(active ? filled : outlined, color: active ? const Color(0xFFE50914) : Colors.white, size: 26, shadows: active ? [const Shadow(color: Color(0xFFE50914), blurRadius: 8)] : null),
                ),
              );
            },
          ),
          if (label.isNotEmpty) ...[const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]))],
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
            Icon(icon, color: active ? const Color(0xFFE50914) : Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: active ? const Color(0xFFE50914) : Colors.white, fontSize: 10)),
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

  const _ShortItem({required this.movie, required this.description, required this.likes, required this.comments, required this.shares});
}
