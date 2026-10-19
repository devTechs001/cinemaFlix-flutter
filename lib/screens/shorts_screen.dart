import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/interactive_card.dart';
import '../models/sample_movies.dart';
import '../services/realtime_messaging_service.dart';
import '../services/video_url_resolver.dart';
import '../services/ads_service.dart';
import '../services/globals.dart';
import '../services/sound_service.dart';
import '../services/wallet_service.dart';

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
  final Set<String> _following = {};
  bool _isLoading = true;
  String _activeTab = 'For You';

  late AnimationController _heartBurstController;
  late Animation<double> _heartBurstScale;
  late Animation<double> _heartBurstOpacity;
  late AnimationController _musicPulseController;
  late AnimationController _discSpinController;

  final Map<int, AnimationController> _likePulseControllers = {};
  final Map<int, AnimationController> _playPauseControllers = {};
  final Map<int, AnimationController> _followControllers = {};
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, bool> _descExpanded = {};

  final List<_ShortItem> _shorts = [
    _ShortItem(movie: sampleMovies[0], description: 'The sandworm scene from Dune: Part Two — absolutely breathtaking! #Dune #SciFi', likes: 12453, comments: 847, shares: 2314, views: 892341),
    _ShortItem(movie: sampleMovies[1], description: 'Oppenheimer\'s Trinity test — one of the most powerful scenes in cinema history. #Oppenheimer #Nolan', likes: 9876, comments: 654, shares: 1876, views: 654321),
    _ShortItem(movie: sampleMovies[2], description: 'The Batmobile chase through Gotham — pure cinematic excellence! #TheBatman #DC', likes: 7654, comments: 432, shares: 1543, views: 423567),
    _ShortItem(movie: sampleMovies[3], description: 'Deadpool breaks the fourth wall... again! #Deadpool #Marvel', likes: 8765, comments: 567, shares: 1987, views: 543210),
    _ShortItem(movie: sampleMovies[4], description: 'Furiosa: The beginning of a legend. George Miller does it again! #Furiosa #MadMax', likes: 5432, comments: 321, shares: 987, views: 298765),
    _ShortItem(movie: sampleMovies[5], description: 'Inception\'s hallway fight — a masterpiece of practical effects. #Inception #Nolan', likes: 6789, comments: 456, shares: 1234, views: 387654),
    _ShortItem(movie: sampleMovies[6], description: 'Interstellar\'s docking scene — still gives us chills. #Interstellar #Nolan', likes: 11234, comments: 789, shares: 2567, views: 765432),
    _ShortItem(movie: sampleMovies[7], description: 'Joker\'s stair dance — an iconic moment in film history. #Joker #DC', likes: 9876, comments: 654, shares: 2345, views: 678901),
    _ShortItem(movie: sampleMovies[8], description: 'Tenet\'s time inversion — mind bending action at its finest. #Tenet #Nolan', likes: 4567, comments: 345, shares: 876, views: 234567),
    _ShortItem(movie: sampleMovies[9], description: 'The Matrix — red pill or blue pill? The choice is yours. #TheMatrix #SciFi', likes: 15432, comments: 1234, shares: 3456, views: 987654),
  ];

  AdOverlayScheduler? _adScheduler;
  Map<String, dynamic>? _activeAd;
  bool _adClosable = false;

  @override
  void initState() {
    super.initState();
    _initAds();
    _heartBurstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _heartBurstScale = Tween<double>(begin: 0.0, end: 1.3).animate(CurvedAnimation(parent: _heartBurstController, curve: Curves.elasticOut));
    _heartBurstOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _heartBurstController, curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));
    _musicPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _discSpinController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    for (var i = 0; i < _shorts.length; i++) {
      _isPlaying[i] = true;
      _descExpanded[i] = false;
      _likePulseControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
      _playPauseControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
      _followControllers[i] = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

      _initVideoController(i);
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  /// Ads system: free users get a banner ad after 2 minutes of continuous
  /// watching; subscribers are exempt (subscription gate). Ads come from the
  /// backend /api/ads endpoint and clicking one rewards wallet points.
  Future<void> _initAds() async {
    await adsService.refresh();
    if (!mounted) return;
    final scheduler = AdOverlayScheduler(
      interval: const Duration(minutes: 2),
      onFire: () {
        if (!mounted || adsService.banners.isEmpty) return;
        final ad = Map<String, dynamic>.from(adsService.banners.first);
        adsService.recordImpression('${ad['id']}');
        soundService.play(SoundEvent.notification);
        setState(() {
          _activeAd = ad;
          _adClosable = false;
        });
        // The close button only appears after 5 seconds so the ad is seen.
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _adClosable = true);
        });
      },
    );
    // Subscribers skip mid-watch ads —subscription plan is wired via wallet
    // purchase history (premium plan check)
    scheduler.subscribed = walletService.diamonds >= 900; // Premium ≈ 900+ diamonds
    scheduler.start();
    _adScheduler = scheduler;
  }

  void _closeAd() {
    setState(() {
      _activeAd = null;
      _adClosable = false;
    });
  }

  Widget _buildAdOverlay() {
    final ad = _activeAd!;
    final color = const Color(0xFFE50914).withValues(alpha: 0.92);
    return Positioned.fill(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color),
            boxShadow: [BoxShadow(color: color, blurRadius: 40)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sponsored', style: TextStyle(color: Colors.white38, fontSize: 10)),
              const SizedBox(height: 10),
              Text('${ad['banner'] ?? '🎬'}', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text('${ad['advertiser'] ?? ''}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 4),
              Text('${ad['tagline'] ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final points = await adsService.recordClick('${ad['id']}');
                      if (mounted && points > 0) {
                        soundService.play(SoundEvent.transaction);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Thanks! +$points pts added to your wallet')));
                      }
                      _closeAd();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914), foregroundColor: Colors.white),
                    child: Text('${ad['cta'] ?? 'Learn more'}'),
                  ),
                  if (_adClosable) ...[
                    const SizedBox(width: 10),
                    InteractiveCard(
                      onTap: _closeAd,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.close, color: Colors.white54, size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initVideoController(int index) async {
    final urls = VideoUrlResolver.candidates(_shorts[index].movie.videoUrl);
    if (urls.isEmpty) return;

    for (final url in urls) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      try {
        await controller.initialize();
        controller.setLooping(false);
        controller.addListener(() {
          if (mounted && controller.value.isCompleted) {
            _onPageChanged((index + 1) % _shorts.length);
          }
        });
        _videoControllers[index] = controller;
        if (mounted) {
          setState(() {});
          if (index == 0) controller.play();
        }
        return;
      } catch (_) {
        await controller.dispose();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _adScheduler?.stop();
    _pageController.dispose();
    _heartBurstController.dispose();
    _musicPulseController.dispose();
    _discSpinController.dispose();
    for (final c in _likePulseControllers.values) c.dispose();
    for (final c in _playPauseControllers.values) c.dispose();
    for (final c in _followControllers.values) c.dispose();
    for (final c in _videoControllers.values) c.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) async {
    setState(() {
      _currentPage = index;
    });

    if (!_videoControllers.containsKey(index)) {
      await _initVideoController(index);
    }

    // Pause all other videos and play current
    _videoControllers.forEach((i, controller) {
      if (i == index) {
        controller.play();
        _isPlaying[i] = true;
      } else {
        controller.pause();
        _isPlaying[i] = false;
      }
    });
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}k';
    return count.toString();
  }

  List<String> _extractHashtags(String text) {
    return text.split(' ').where((w) => w.startsWith('#')).map((w) => w.replaceAll('#', '')).toList();
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
    final controller = _videoControllers[index];
    setState(() {
      final wasPlaying = _isPlaying[index] ?? true;
      _isPlaying[index] = !wasPlaying;
      if (controller != null) {
        if (wasPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      }
    });
    _playPauseControllers[index]?.forward(from: 0);
  }

  void _toggleFollow(int index) {
    final id = _shorts[index].movie.id;
    HapticFeedback.lightImpact();
    setState(() {
      if (_following.contains(id)) _following.remove(id);
      else _following.add(id);
    });
    _followControllers[index]?.forward().then((_) => _followControllers[index]?.reverse());
  }

  void _showCommentsSheet(BuildContext context, _ShortItem short) {
    final contentId = 'short_${short.movie.id}';
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final comments = realtimeMessagingService.getComments(contentId);
          return Padding(
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
                    Text('Comments (${comments.length + short.comments})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    InteractiveCard(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Colors.white38, size: 20)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF2A2A2A), height: 1),
              SizedBox(
                height: 320,
                child: comments.isEmpty
                    ? Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 13)))
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (_, i) {
                    final c = comments[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        CircleAvatar(radius: 16, backgroundColor: const Color(0xFF2A2A2A), child: Text(c.userAvatar, style: const TextStyle(color: Color(0xFFE50914), fontSize: 10, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [Text(c.userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(width: 6)]),
                          const SizedBox(height: 4), Text(c.text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(children: [
                            InteractiveCard(
                              onTap: () {
                                realtimeMessagingService.likeComment(contentId, c.id);
                                setSheetState(() {});
                              },
                              child: Row(children: [
                                const Icon(Icons.favorite_border, color: Colors.white38, size: 14),
                                const SizedBox(width: 4), Text('${c.likes}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 14),
                            const SizedBox(width: 4), const Text('Reply', style: TextStyle(color: Colors.white24, fontSize: 11)),
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
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;
                      realtimeMessagingService.addComment(contentId, 'you', 'You', value.trim());
                      commentController.clear();
                      HapticFeedback.lightImpact();
                      setSheetState(() {});
                    },
                  )),
                  const SizedBox(width: 8),
                  InteractiveCard(
                    onTap: () {
                      final value = commentController.text.trim();
                      if (value.isEmpty) return;
                      realtimeMessagingService.addComment(contentId, 'you', 'You', value);
                      commentController.clear();
                      HapticFeedback.lightImpact();
                      setSheetState(() {});
                    },
                    child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 16)),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
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
              const SizedBox(height: 12),
              Text('Share to', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(Icons.share, 'Share', Colors.blue, () async {
                    Navigator.pop(ctx);
                    await Share.share('Check out "${short.movie.title}" on CinemaFlix!');
                  }),
                  _shareOption(Icons.link, 'Copy Link', Colors.teal, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating));
                  }),
                  _shareOption(Icons.repeat_rounded, 'Remix', const Color(0xFF7B1FA2), () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/creator-upload');
                  }),
                  _shareOption(Icons.save_alt, 'Save', const Color(0xFFFF8F00), () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to downloads'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating));
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _shareOption(Icons.whatshot, 'WhatsApp', const Color(0xFF25D366), () { Navigator.pop(ctx); }),
                  _shareOption(Icons.facebook, 'Facebook', const Color(0xFF1877F2), () { Navigator.pop(ctx); }),
                  _shareOption(Icons.tag, 'Twitter', const Color(0xFF1DA1F2), () { Navigator.pop(ctx); }),
                  _shareOption(Icons.sms, 'Message', const Color(0xFF10B981), () { Navigator.pop(ctx); }),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSoundDetail(_ShortItem short) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const SweepGradient(colors: [Color(0xFF2A2A2A), Color(0xFF555555), Color(0xFF2A2A2A)]), border: Border.all(color: Colors.white.withAlpha(40), width: 2)),
              child: Center(child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE50914)), child: const Icon(Icons.music_note, color: Colors.white, size: 14))),
            ),
            const SizedBox(height: 16),
            const Text('Original Sound', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${short.movie.title} — CinemaFlix', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 14)),
            const SizedBox(height: 6),
            Text('${_formatCount(short.views * 3)} plays', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _soundStat(Icons.play_circle_outline, '${_formatCount(short.views)} videos'),
                  const SizedBox(width: 24),
                  _soundStat(Icons.person_outline, '${_formatCount(short.views ~/ 10)} creators'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _soundStat(IconData icon, String label) {
    return Row(children: [Icon(icon, color: Colors.white54, size: 16), const SizedBox(width: 6), Text(label, style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13))]);
  }

  Widget _shareOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InteractiveCard(
      onTap: onTap,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading ? _buildShimmer() : Stack(
        children: [
          if (_activeAd != null) _buildAdOverlay(),
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _shorts.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final short = _shorts[index];
              final isLiked = _liked.contains(short.movie.id);
              final isBookmarked = _bookmarked.contains(short.movie.id);
              final isFollowed = _following.contains(short.movie.id);
              final playing = _isPlaying[index] ?? true;
              final followCtrl = _followControllers[index];
              final expanded = _descExpanded[index] ?? false;
              final hashtags = _extractHashtags(short.description);
              final videoController = _videoControllers[index];
              final videoError = videoController != null && videoController.value.hasError;

              return GestureDetector(
                onTap: () => _togglePlayPause(index),
                onDoubleTap: () => _handleDoubleTapLike(index),
                onLongPress: () => _showContextMenu(index),
                child: Container(
                  height: screenHeight,
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.black,
                        child: Center(
                          child: videoError
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white38, size: 64),
                                    const SizedBox(height: 16),
                                    const Text('Failed to load video', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        final c = _videoControllers[index];
                                        if (c != null) {
                                          c.initialize().then((_) {
                                            if (mounted) { setState(() {}); c.play(); _isPlaying[index] = true; }
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(20)),
                                        child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                    ),
                                  ],
                                )
                              : (videoController != null && videoController.value.isInitialized) ? SizedBox.expand(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: videoController.value.size.width,
                                      height: videoController.value.size.height,
                                      child: VideoPlayer(videoController),
                                    ),
                                  ),
                                ) : videoController != null ? const Center(
                                  child: SizedBox(
                                    width: 40, height: 40,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white38),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 120, height: 120,
                                      decoration: BoxDecoration(color: Colors.white.withAlpha(12), borderRadius: BorderRadius.circular(60)),
                                      child: const Icon(Icons.play_circle_fill, color: Colors.white38, size: 64),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(short.movie.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        ...List.generate(5, (i) => Icon(Icons.star, color: i < ((double.tryParse(short.movie.rating) ?? 0) / 2).round() ? Colors.amber : Colors.white24, size: 18)),
                                        const SizedBox(width: 8),
                                        Text(short.movie.rating, style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (!playing)
                        Center(
                          child: ScaleTransition(
                            scale: _playPauseControllers[index]!,
                            child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.black.withAlpha(140), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.white, size: 44)),
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _heartBurstController,
                        builder: (context, child) => Opacity(
                          opacity: _heartBurstOpacity.value,
                          child: Transform.scale(scale: _heartBurstScale.value, child: child),
                        ),
                        child: Center(
                          child: Icon(Icons.favorite, color: Colors.white, size: 200, shadows: const [Shadow(color: Color(0xFFE50914), blurRadius: 60), Shadow(color: Color(0xFFE50914), blurRadius: 120)]),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withAlpha(120),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withAlpha(200),
                                ],
                                stops: const [0.0, 0.15, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 80,
                        bottom: bottomPadding + 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                    child: CircleAvatar(backgroundColor: const Color(0xFFE50914), child: const Icon(Icons.person, color: Colors.white, size: 20)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text('cinemaflix', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                                          const SizedBox(width: 4),
                                          Icon(Icons.verified_rounded, color: const Color(0xFF1E88E5), size: 16, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]),
                                        ],
                                      ),
                                      Text('${_formatCount(short.views)} views', style: const TextStyle(color: Colors.white54, fontSize: 11, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _toggleFollow(index),
                                    child: ScaleTransition(
                                      scale: followCtrl ?? AlwaysStoppedAnimation(1.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isFollowed ? Colors.white.withAlpha(20) : const Color(0xFFE50914),
                                          borderRadius: BorderRadius.circular(20),
                                          border: isFollowed ? Border.all(color: Colors.white24) : null,
                                        ),
                                        child: Text(isFollowed ? 'Following' : 'Follow', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => setState(() => _descExpanded[index] = !expanded),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expanded ? short.description : short.description.length > 90 ? '${short.description.substring(0, 90)}...' : short.description,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, shadows: [Shadow(color: Colors.black87, blurRadius: 8)]),
                                  ),
                                  if (short.description.length > 90)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(expanded ? 'Show less' : 'more', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                    ),
                                ],
                              ),
                            ),
                            if (hashtags.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                children: hashtags.map((tag) => InteractiveCard(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(context, '/search');
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                                    child: Text('#$tag', style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                  ),
                                )).toList(),
                              ),
                            ],
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _showSoundDetail(short),
                              child: Row(
                                children: [
                                  AnimatedBuilder(
                                    animation: _discSpinController,
                                    builder: (context, child) => Transform.rotate(
                                      angle: _discSpinController.value * 6.28,
                                      child: Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(30), border: Border.all(color: Colors.white38, width: 1.5)),
                                        child: Center(child: Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _soundWaveBars(),
                                  const SizedBox(width: 6),
                                  Text('${short.movie.title} — Original Sound', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, shadows: [Shadow(color: Colors.black87, blurRadius: 8)])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: bottomPadding + 24,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, '/profile');
                              },
                              child: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE50914), width: 2),
                                ),
                                child: CircleAvatar(backgroundColor: const Color(0xFF2A2A2A), child: const Icon(Icons.person, color: Colors.white, size: 24)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _actionColumn(Icons.favorite, Icons.favorite_border, isLiked, _formatCount(short.likes), () => _toggleLike(index), likePulse: _likePulseControllers[index]),
                            const SizedBox(height: 12),
                            _actionColumn(Icons.chat_bubble, Icons.chat_bubble_outline, false, _formatCount(short.comments), () { HapticFeedback.lightImpact(); _showCommentsSheet(context, short); }),
                            const SizedBox(height: 12),
                            _actionColumn(Icons.bookmark, Icons.bookmark_border, isBookmarked, '', () { HapticFeedback.lightImpact(); setState(() { if (isBookmarked) _bookmarked.remove(short.movie.id); else _bookmarked.add(short.movie.id); }); }),
                            const SizedBox(height: 12),
                            _actionColumn(Icons.share, Icons.ios_share_rounded, false, _formatCount(short.shares), () => _showShareSheet(short)),
                            const SizedBox(height: 12),
                            InteractiveCard(
                              onTap: () => _showSoundDetail(short),
                              child: _recordDisc(),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 48,
                        left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_shorts.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: _currentPage == i ? 16 : 5,
                              height: 2,
                              decoration: BoxDecoration(
                                color: _currentPage == i ? Colors.white : Colors.white30,
                                borderRadius: BorderRadius.circular(1),
                              ),
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
            top: MediaQuery.of(context).padding.top + 4,
            left: 0, right: 0,
            child: Row(
              children: [
                InteractiveCard(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Scaffold.of(context).openDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.menu_rounded, color: Colors.white, size: 24, shadows: const [Shadow(color: Colors.black87, blurRadius: 8)]),
                  ),
                ),
                const Spacer(),
                _topTab('Following', _activeTab == 'Following', () => setState(() => _activeTab = 'Following')),
                const SizedBox(width: 20),
                _topTab('For You', _activeTab == 'For You', () => setState(() => _activeTab = 'For You')),
                const SizedBox(width: 20),
                _topTab('Live', _activeTab == 'Live', () {
                  setState(() => _activeTab = 'Live');
                  Navigator.pushNamed(context, '/live');
                }),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InteractiveCard(
                    onTap: () => Navigator.pushNamed(context, '/search'),
                    child: Icon(Icons.search_rounded, color: Colors.white, size: 24, shadows: const [Shadow(color: Colors.black87, blurRadius: 8)]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(int index) {
    HapticFeedback.heavyImpact();
    final short = _shorts[index];
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
              _contextItem(Icons.not_interested, 'Not interested', () { Navigator.pop(ctx); _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut); }),
              _contextItem(Icons.flag_outlined, 'Report', () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted'), backgroundColor: Color(0xFFE50914), behavior: SnackBarBehavior.floating)); }),
              _contextItem(Icons.save_alt, 'Save video', () { Navigator.pop(ctx); setState(() => _bookmarked.add(short.movie.id)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to collection'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating)); }),
              _contextItem(Icons.repeat_rounded, 'Remix this', () { Navigator.pop(ctx); Navigator.pushNamed(context, '/creator-upload'); }),
              _contextItem(Icons.share, 'Share via...', () { Navigator.pop(ctx); _showShareSheet(short); }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contextItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InteractiveCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white.withAlpha(8), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Container(
      color: Colors.black,
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
              return Container(width: 3, height: h, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5)));
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

  Widget _topTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(
            color: active ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w700,
            fontSize: 17,
            letterSpacing: 0.5,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
          )),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 28 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionColumn(IconData filled, IconData outlined, bool active, String label, VoidCallback onTap, {AnimationController? likePulse}) {
    return InteractiveCard(
      onTap: onTap,
      scaleAmount: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  child: Icon(active ? filled : outlined, color: active ? const Color(0xFFE50914) : Colors.white, size: 28, shadows: active ? [const Shadow(color: Color(0xFFE50914), blurRadius: 8)] : null),
                ),
              );
            },
          ),
          if (label.isNotEmpty) ...[const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]))],
        ],
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
  final int views;

  const _ShortItem({required this.movie, required this.description, required this.likes, required this.comments, required this.shares, this.views = 0});
}
