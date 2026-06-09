import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/sample_movies.dart';

class MoviePlayScreen extends StatefulWidget {
  final SampleMovie movie;

  const MoviePlayScreen({super.key, required this.movie});

  @override
  State<MoviePlayScreen> createState() => _MoviePlayScreenState();
}

class _MoviePlayScreenState extends State<MoviePlayScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _controlsVisible = true;
  bool _isPlaying = false;
  Timer? _controlsTimer;
  late AnimationController _glowController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
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

  void _showControlsTemporarily() {
    setState(() => _controlsVisible = true);
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
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

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.movie.videoUrl!));
    await _videoController!.initialize();

    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _videoController!.value.isPlaying;
        });
        if (_videoController!.value.isPlaying) {
          _showControlsTemporarily();
        }
      }
    });

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
      overlay: _controlsVisible ? _buildOverlay() : const SizedBox.shrink(),
    );

    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _controlsTimer?.cancel();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _seekRelative(int seconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    final pos = _videoController!.value.position;
    final newPos = pos + Duration(seconds: seconds);
    final duration = _videoController!.value.duration;
    final clamped = newPos < Duration.zero ? Duration.zero : (newPos > duration ? duration : newPos);
    _videoController!.seekTo(clamped);
    HapticFeedback.lightImpact();
    _showControlsTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            if (_isInitialized && _chewieController != null)
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: _isPlaying
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE50914).withAlpha((40 * _glowController.value).toInt()),
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
            else if (_isInitialized)
              _buildPlaceholder()
            else
              _buildPlaceholder(),

            if (_controlsVisible && _isInitialized) _buildOverlay(),

            if (_isInitialized && _chewieController != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
              ),

            if (!_controlsVisible && _isPlaying)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {},
                  child: Container(
                    width: 60,
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(Icons.brightness_6, color: Colors.white.withAlpha(40), size: 20),
                    ),
                  ),
                ),
              ),

            if (!_controlsVisible && _isPlaying)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {},
                  child: Container(
                    width: 60,
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(Icons.volume_up, color: Colors.white.withAlpha(40), size: 20),
                    ),
                  ),
                ),
              ),
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
                    child: const Icon(Icons.replay_10, color: Colors.white, size: 28),
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
                    child: const Icon(Icons.forward_10, color: Colors.white, size: 28),
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
                  Colors.black.withAlpha(200),
                  Colors.transparent,
                ],
              ),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 40,
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
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((15 * _pulseController.value).toInt()),
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE50914).withAlpha((20 * _pulseController.value).toInt()),
                        blurRadius: 30 + _pulseController.value * 20,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white.withAlpha((80 + (80 * _pulseController.value)).toInt()),
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
                if (widget.movie.videoUrl == null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'No video URL available',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
                        ),
                        SizedBox(width: 8),
                        Text('Loading...', style: TextStyle(color: Colors.white38, fontSize: 13)),
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
