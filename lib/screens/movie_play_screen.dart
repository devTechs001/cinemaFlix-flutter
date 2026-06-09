import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/sample_movies.dart';
import '../services/globals.dart';
import '../services/download_service.dart';

class MoviePlayScreen extends StatefulWidget {
  final SampleMovie movie;

  const MoviePlayScreen({super.key, required this.movie});

  @override
  State<MoviePlayScreen> createState() => _MoviePlayScreenState();
}

class _MoviePlayScreenState extends State<MoviePlayScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _controlsVisible = true;
  bool _isPlaying = false;
  bool _isLocked = false;
  bool _isOffline = false;
  double _playbackSpeed = 1.0;
  bool _isLandscapeLocked = false;
  Timer? _controlsTimer;
  Timer? _sleepTimer;
  DateTime? _sleepEndTime;
  late AnimationController _glowController;
  late AnimationController _pulseController;

  final List<double> _speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  final List<Map<String, dynamic>> _sleepOptions = const [
    {'label': '30 min', 'duration': Duration(minutes: 30)},
    {'label': '1 hour', 'duration': Duration(hours: 1)},
    {'label': '2 hours', 'duration': Duration(hours: 2)},
    {'label': 'End of movie', 'duration': null},
  ];

  @override
  void initState() {
    super.initState();
    connectivityService.addListener(_onConnectivityChanged);
    _isOffline = !connectivityService.isOnline;
    _initPlayer();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _showControlsTemporarily();
  }

  void _onConnectivityChanged() {
    if (mounted) {
      setState(() => _isOffline = !connectivityService.isOnline);
    }
  }

  void _showControlsTemporarily() {
    if (_isLocked) return;
    setState(() => _controlsVisible = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && !_isLocked) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) {
      setState(() => _isLocked = false);
      _showControlsTemporarily();
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) {
      _showControlsTemporarily();
    }
  }

  Future<void> _initPlayer() async {
    if (widget.movie.videoUrl == null) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    if (_isOffline) {
      if (mounted) setState(() => _isInitialized = true);
      return;
    }

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.movie.videoUrl!),
    );
    try {
      await _videoController!.initialize();

      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _videoController!.value.isPlaying;
          });
          if (_videoController!.value.isPlaying) {
            _showControlsTemporarily();
          }
          if (_sleepEndTime != null &&
              DateTime.now().isAfter(_sleepEndTime!)) {
            _videoController!.pause();
            _sleepTimer?.cancel();
            _sleepEndTime = null;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sleep timer ended'),
                  backgroundColor: Color(0xFFE50914),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }
      });

      _videoController!.setPlaybackSpeed(_playbackSpeed);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE50914),
          bufferedColor: Colors.white24,
          handleColor: const Color(0xFFE50914),
          backgroundColor: Colors.white12,
        ),
        placeholder: _buildPlaceholder(),
        overlay: _controlsVisible && !_isLocked
            ? _buildOverlay()
            : const SizedBox.shrink(),
      );

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  void _setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    _videoController?.setPlaybackSpeed(speed);
    HapticFeedback.lightImpact();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Speed: ${speed}x'),
        backgroundColor: const Color(0xFFE50914),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    if (duration == null) {
      final pos = _videoController?.value.position ?? Duration.zero;
      final total = _videoController?.value.duration ?? Duration.zero;
      final remaining = total - pos;
      _sleepEndTime = DateTime.now().add(remaining);
    } else {
      _sleepEndTime = DateTime.now().add(duration);
      _sleepTimer = Timer(duration, () {
        _videoController?.pause();
        _sleepEndTime = null;
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sleep timer ended'),
              backgroundColor: Color(0xFFE50914),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    setState(() {});
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          duration == null
              ? 'Sleep: end of movie'
              : 'Sleep: ${duration.inMinutes} min',
        ),
        backgroundColor: const Color(0xFFE50914),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleOrientationLock() {
    _isLandscapeLocked = !_isLandscapeLocked;
    if (_isLandscapeLocked) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _showSpeedSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Playback Speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...(_speedOptions.map((speed) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _setPlaybackSpeed(speed),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _playbackSpeed == speed
                        ? const Color(0xFFE50914).withAlpha(40)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _playbackSpeed == speed
                          ? const Color(0xFFE50914)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${speed}x',
                        style: TextStyle(
                          color: _playbackSpeed == speed
                              ? const Color(0xFFE50914)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_playbackSpeed == speed)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFE50914),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSleepSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sleep Timer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_sleepEndTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Sleeping in ${_sleepEndTime!.difference(DateTime.now()).inMinutes + 1} min',
                style: const TextStyle(color: Color(0xFFE50914), fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            ...(_sleepOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _setSleepTimer(opt['duration'] as Duration?),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt['duration'] == null
                            ? Icons.movie_outlined
                            : Icons.timer_outlined,
                        color: Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        opt['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ))),
            if (_sleepEndTime != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  _sleepTimer?.cancel();
                  _sleepEndTime = null;
                  setState(() {});
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(60)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined,
                          color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Cancel Sleep Timer',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.more_horiz, color: Color(0xFFE50914), size: 22),
                ),
                const SizedBox(width: 12),
                const Text('More Options', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _moreOption(Icons.download_rounded, 'Download Movie', 'Save for offline viewing', () {
              downloadService.startDownload(
                widget.movie.id.toString(),
                widget.movie.title,
                widget.movie.genre,
                widget.movie.year,
                widget.movie.rating,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download started'),
                  backgroundColor: Color(0xFFE50914),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }),
            _moreOption(Icons.download_for_offline, 'Downloads', 'View your downloads', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/downloads');
            }),
            _moreOption(Icons.share_outlined, 'Share', 'Share this movie', () {
              Navigator.pop(context);
            }),
            _moreOption(Icons.playlist_add, 'Add to Watchlist', 'Save for later', () {
              Navigator.pop(context);
            }),
            _moreOption(Icons.groups_rounded, 'Watch Party', 'Watch with friends', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/watch-party', arguments: {
                'movieId': widget.movie.id,
                'movieTitle': widget.movie.title,
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _moreOption(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    connectivityService.removeListener(_onConnectivityChanged);
    _videoController?.dispose();
    _chewieController?.dispose();
    _controlsTimer?.cancel();
    _sleepTimer?.cancel();
    _glowController.dispose();
    _pulseController.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _seekRelative(int seconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final pos = _videoController!.value.position;
    final newPos = pos + Duration(seconds: seconds);
    final duration = _videoController!.value.duration;
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > duration ? duration : newPos);
    _videoController!.seekTo(clamped);
    HapticFeedback.lightImpact();
    _showControlsTemporarily();
  }

  Future<bool> _onWillPop() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onWillPop().then((_) => Navigator.pop(context));
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              if (_isInitialized && _chewieController != null && !_isOffline)
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: _isPlaying
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE50914).withAlpha(
                                      (40 * _glowController.value).toInt()),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                      child: Chewie(controller: _chewieController!),
                    );
                  },
                )
              else
                _buildPlaceholder(),

              if (_controlsVisible && _isInitialized && !_isLocked)
                _buildOverlay(),

              _buildTopBar(),

              if (_isOffline)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withAlpha(200),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.wifi_off_rounded,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Internet Connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect to the internet to stream\n${widget.movie.title}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () async {
                              await connectivityService.checkNow();
                              if (connectivityService.isOnline) {
                                _isOffline = false;
                                _initPlayer();
                                setState(() {});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE50914),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Retry',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (!_controlsVisible && _isPlaying && !_isLocked && !_isOffline)
                _buildEdgeGestureAreas(),

              if (_isInitialized && _controlsVisible && !_isLocked && !_isOffline)
                _buildSkipBadges(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _controlsVisible || !_isPlaying ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 4,
            right: 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(180),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 22),
                    onPressed: () {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.landscapeLeft,
                        DeviceOrientation.landscapeRight,
                      ]);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (_sleepEndTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE50914).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.nightlight_round,
                            color: Color(0xFFE50914), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_sleepEndTime!.difference(DateTime.now()).inMinutes + 1}m',
                          style: const TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (_isOffline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.redAccent, size: 14),
                        SizedBox(width: 3),
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert,
                        color: Colors.white, size: 22),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showMoreMenu();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeGestureAreas() {
    return Stack(
      children: [
        Positioned(
          left: 0, top: 0, bottom: 0,
          child: GestureDetector(
            onTap: _toggleControls,
            onVerticalDragUpdate: (details) {
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 60,
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  Icons.chevron_left,
                  color: Colors.white.withAlpha(30),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0, top: 0, bottom: 0,
          child: GestureDetector(
            onTap: _toggleControls,
            onVerticalDragUpdate: (details) {
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 60,
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withAlpha(30),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipBadges() {
    return Positioned(
      top: 90,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _skipBadge(Icons.skip_next_rounded, 'Skip Intro', () {
            _videoController?.seekTo(const Duration(seconds: 90));
            HapticFeedback.lightImpact();
          }),
          const SizedBox(height: 8),
          _skipBadge(Icons.flag_outlined, 'Skip Credits', () {
            final d = _videoController?.value.duration ?? Duration.zero;
            _videoController?.seekTo(d - const Duration(seconds: 60));
            HapticFeedback.lightImpact();
          }),
        ],
      ),
    );
  }

  Widget _skipBadge(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _seekRelative(-10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.replay_10,
                        color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () {
                    if (_videoController == null) return;
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                        _isPlaying = false;
                      } else {
                        _videoController!.play();
                        _isPlaying = true;
                        _showControlsTemporarily();
                      }
                    });
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withAlpha(100),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () => _seekRelative(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(100),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.forward_10,
                        color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withAlpha(220),
                  Colors.transparent,
                ],
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 30,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.movie.year} \u2022 ${widget.movie.genre}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _boosterButton(
                      icon: Icons.speed,
                      label: '${_playbackSpeed}x',
                      active: _playbackSpeed != 1.0,
                      onTap: _showSpeedSheet,
                    ),
                    const SizedBox(width: 8),
                    _boosterButton(
                      icon: Icons.download_rounded,
                      label: 'Download',
                      active: false,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        downloadService.startDownload(
                          widget.movie.id.toString(),
                          widget.movie.title,
                          widget.movie.genre,
                          widget.movie.year,
                          widget.movie.rating,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Download started'),
                            backgroundColor: Color(0xFFE50914),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _boosterButton(
                      icon: _isLandscapeLocked
                          ? Icons.screen_lock_landscape
                          : Icons.screen_rotation,
                      label: _isLandscapeLocked ? 'Locked' : 'Rotate',
                      active: _isLandscapeLocked,
                      onTap: _toggleOrientationLock,
                    ),
                    const SizedBox(width: 8),
                    _boosterButton(
                      icon: _sleepEndTime != null
                          ? Icons.nightlight_round
                          : Icons.nightlight_outlined,
                      label: _sleepEndTime != null ? 'Sleep' : 'Timer',
                      active: _sleepEndTime != null,
                      onTap: _showSleepSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_sleepEndTime != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.nightlight_round,
                            color: Color(0xFFE50914), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-stop in ${_sleepEndTime!.difference(DateTime.now()).inMinutes + 1} min',
                          style: const TextStyle(
                            color: Color(0xFFE50914),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boosterButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFE50914).withAlpha(50)
              : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFFE50914).withAlpha(120)
                : Colors.white12,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? const Color(0xFFE50914) : Colors.white70,
                size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFFE50914) : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.movie.gradientStart,
            widget.movie.gradientEnd,
            Colors.black,
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                        (15 * _pulseController.value).toInt()),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withAlpha(
                            (20 * _pulseController.value).toInt()),
                        blurRadius: 30 + _pulseController.value * 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white.withAlpha(
                        (80 + (80 * _pulseController.value)).toInt()),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.movie.year} \u2022 ${widget.movie.genre}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                if (_isOffline) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withAlpha(60)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off,
                            color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Offline - waiting for connection',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (widget.movie.videoUrl == null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'No video URL available',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white38,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
