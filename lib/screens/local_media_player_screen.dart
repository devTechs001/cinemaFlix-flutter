import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

/// Vertical-scroll local player for device MP4 / MP3 files.
///
/// Swipe up/down to move through the playlist. Each page owns a real
/// [VideoPlayerController] or [AudioPlayer] bound to the file on disk.
class LocalMediaPlayerScreen extends StatefulWidget {
  const LocalMediaPlayerScreen({super.key});

  @override
  State<LocalMediaPlayerScreen> createState() => _LocalMediaPlayerScreenState();
}

class _LocalMediaPlayerScreenState extends State<LocalMediaPlayerScreen> {
  List<Map<String, String>> _playlist = [];
  int _index = 0;
  final PageController _pageController = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_playlist.isNotEmpty) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final raw = args?['playlist'];
    if (raw is List && raw.isNotEmpty) {
      _playlist = [
        for (final item in raw)
          if (item is Map)
            {
              'path': '${item['path'] ?? ''}',
              'type': '${item['type'] ?? 'video'}',
              'name': '${item['name'] ?? 'Media'}',
            },
      ];
    } else if (args != null) {
      _playlist = [
        {
          'path': '${args['path'] ?? ''}',
          'type': '${args['type'] ?? 'video'}',
          'name': '${args['name'] ?? 'Media'}',
        },
      ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_playlist.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Media Player'),
        ),
        body: const Center(
          child: Text('No file selected', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _playlist.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final item = _playlist[i];
          return _VerticalMediaPage(
            key: ValueKey(item['path']),
            path: item['path'] ?? '',
            type: item['type'] ?? 'video',
            name: item['name'] ?? 'Media',
            index: i,
            total: _playlist.length,
            active: i == _index,
            onPrev: i > 0
                ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    )
                : null,
            onNext: i < _playlist.length - 1
                ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    )
                : null,
          );
        },
      ),
    );
  }
}

class _VerticalMediaPage extends StatefulWidget {
  final String path;
  final String type;
  final String name;
  final int index;
  final int total;
  final bool active;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _VerticalMediaPage({
    super.key,
    required this.path,
    required this.type,
    required this.name,
    required this.index,
    required this.total,
    required this.active,
    this.onPrev,
    this.onNext,
  });

  @override
  State<_VerticalMediaPage> createState() => _VerticalMediaPageState();
}

class _VerticalMediaPageState extends State<_VerticalMediaPage> {
  VideoPlayerController? _video;
  AudioPlayer? _audio;
  bool _ready = false;
  bool _playing = false;
  bool _loop = true;
  bool _muted = false;
  bool _liked = false;
  bool _showControls = true;
  double _speed = 1.0;
  double _volume = 0.9;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _error;
  Timer? _hideTimer;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;

  bool get _isVideo => widget.type == 'video';
  bool get _isAudio => widget.type == 'audio';
  bool get _isImage => widget.type == 'image';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didUpdateWidget(covariant _VerticalMediaPage old) {
    super.didUpdateWidget(old);
    if (old.active && !widget.active) {
      _pause();
    } else if (!old.active && widget.active && _ready) {
      _play();
    }
  }

  Future<void> _boot() async {
    if (kIsWeb || widget.path.isEmpty) {
      setState(() => _error = 'This file cannot be opened here');
      return;
    }
    try {
      final file = File(widget.path);
      if (!file.existsSync()) {
        setState(() => _error = 'File not found');
        return;
      }
      if (_isVideo) {
        final c = VideoPlayerController.file(file);
        await c.initialize();
        await c.setLooping(_loop);
        await c.setVolume(_volume);
        c.addListener(_onVideoTick);
        _video = c;
        _duration = c.value.duration;
        _ready = true;
        if (widget.active) await c.play();
        _playing = widget.active;
      } else if (_isAudio) {
        final p = AudioPlayer();
        await p.setReleaseMode(_loop ? ReleaseMode.loop : ReleaseMode.stop);
        await p.setVolume(_volume);
        await p.setSource(DeviceFileSource(widget.path));
        _posSub = p.onPositionChanged.listen((d) {
          if (mounted) setState(() => _position = d);
        });
        _durSub = p.onDurationChanged.listen((d) {
          if (mounted) setState(() => _duration = d);
        });
        _completeSub = p.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _playing = _loop);
        });
        _audio = p;
        _ready = true;
        if (widget.active) {
          await p.resume();
          _playing = true;
        }
      } else {
        _ready = true;
      }
    } catch (e) {
      _error = 'Could not play this file';
      debugPrint('local player: $e');
    }
    if (mounted) setState(() {});
    _armHide();
  }

  void _onVideoTick() {
    final c = _video;
    if (c == null || !mounted) return;
    setState(() {
      _position = c.value.position;
      _duration = c.value.duration;
      _playing = c.value.isPlaying;
    });
  }

  void _armHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _playing) setState(() => _showControls = false);
    });
  }

  Future<void> _play() async {
    if (_isVideo) await _video?.play();
    if (_isAudio) await _audio?.resume();
    if (mounted) setState(() => _playing = true);
    _armHide();
  }

  Future<void> _pause() async {
    if (_isVideo) await _video?.pause();
    if (_isAudio) await _audio?.pause();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _toggle() async {
    HapticFeedback.lightImpact();
    if (_playing) {
      await _pause();
    } else {
      await _play();
    }
  }

  Future<void> _seek(Duration d) async {
    final clamped = d < Duration.zero
        ? Duration.zero
        : (_duration == Duration.zero || d < _duration ? d : _duration);
    if (_isVideo) await _video?.seekTo(clamped);
    if (_isAudio) await _audio?.seek(clamped);
  }

  Future<void> _skip(int seconds) async {
    HapticFeedback.selectionClick();
    await _seek(_position + Duration(seconds: seconds));
  }

  Future<void> _setSpeed(double s) async {
    _speed = s;
    if (_isVideo) await _video?.setPlaybackSpeed(s);
    if (_isAudio) await _audio?.setPlaybackRate(s);
    if (mounted) setState(() {});
  }

  Future<void> _setVolume(double v) async {
    _volume = v;
    _muted = v <= 0.001;
    if (_isVideo) await _video?.setVolume(v);
    if (_isAudio) await _audio?.setVolume(v);
    if (mounted) setState(() {});
  }

  Future<void> _toggleMute() async {
    HapticFeedback.lightImpact();
    if (_muted) {
      await _setVolume(_volume <= 0.001 ? 0.9 : _volume);
      _muted = false;
    } else {
      if (_isVideo) await _video?.setVolume(0);
      if (_isAudio) await _audio?.setVolume(0);
      _muted = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleLoop() async {
    HapticFeedback.lightImpact();
    _loop = !_loop;
    if (_isVideo) await _video?.setLooping(_loop);
    if (_isAudio) {
      await _audio?.setReleaseMode(_loop ? ReleaseMode.loop : ReleaseMode.stop);
    }
    if (mounted) setState(() {});
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) _armHide();
      },
      onDoubleTap: _toggle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black, child: _stage()),
          if (_showControls) _topBar(),
          if (_showControls) _sideRail(),
          if (_showControls) _bottomBar(),
          if (!_playing && _showControls && !_isImage)
            const Center(
              child: Icon(Icons.play_circle, color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }

  Widget _stage() {
    if (_error != null) {
      return _fallback(icon: Icons.error_outline, subtitle: _error!);
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }
    if (_isVideo && _video != null && _video!.value.isInitialized) {
      final size = _video!.value.size;
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width == 0 ? 16 : size.width,
            height: size.height == 0 ? 9 : size.height,
            child: VideoPlayer(_video!),
          ),
        ),
      );
    }
    if (_isImage && !kIsWeb && widget.path.isNotEmpty) {
      return SizedBox.expand(
        child: Image.file(
          File(widget.path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(icon: Icons.broken_image, subtitle: 'Could not open image'),
        ),
      );
    }
    if (_isAudio) {
      return _fallback(
        icon: _playing ? Icons.audiotrack : Icons.music_note,
        subtitle: widget.path.split('/').last,
        visualizer: true,
      );
    }
    return _fallback(icon: Icons.image, subtitle: 'Preview');
  }

  Widget _fallback({required IconData icon, required String subtitle, bool visualizer = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A0A12), Color(0xFF0A0A0A)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFF7C3AED)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE50914).withAlpha(80), blurRadius: 28),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 72),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          if (visualizer) ...[
            const SizedBox(height: 18),
            _bars(),
          ],
        ],
      ),
    );
  }

  Widget _bars() {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(22, (i) {
          final h = _playing
              ? (8.0 + (math.sin(i * 0.7) * 12 + math.cos(i * 1.3) * 8)).clamp(6.0, 32.0)
              : 6.0;
          return Container(
            width: 3,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withAlpha(140 + (i * 4) % 80),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${widget.index + 1} / ${widget.total}  ·  swipe for next',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _chip(_isVideo ? 'MP4' : _isAudio ? 'MP3' : widget.type.toUpperCase()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withAlpha(40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE50914).withAlpha(90)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFE50914), fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _sideRail() {
    return Positioned(
      right: 10,
      bottom: 118,
      child: Column(
        children: [
          _railBtn(Icons.favorite, _liked ? const Color(0xFFE50914) : Colors.white, () {
            setState(() => _liked = !_liked);
          }),
          const SizedBox(height: 14),
          _railBtn(_muted ? Icons.volume_off : Icons.volume_up, Colors.white, _toggleMute),
          const SizedBox(height: 14),
          _railBtn(_loop ? Icons.repeat_one : Icons.repeat, _loop ? const Color(0xFFE50914) : Colors.white, _toggleLoop),
          const SizedBox(height: 14),
          _railBtn(Icons.speed, Colors.white, _speedSheet),
          const SizedBox(height: 14),
          _railBtn(Icons.share, Colors.white, () {
            Share.share(widget.path);
          }),
        ],
      ),
    );
  }

  Widget _railBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _bottomBar() {
    final totalMs = _duration.inMilliseconds;
    final value = totalMs <= 0 ? 0.0 : (_position.inMilliseconds / totalMs).clamp(0.0, 1.0);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(_fmt(_position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: value,
                        activeColor: const Color(0xFFE50914),
                        inactiveColor: Colors.white24,
                        onChanged: (v) {
                          if (totalMs <= 0) return;
                          _seek(Duration(milliseconds: (v * totalMs).round()));
                        },
                      ),
                    ),
                  ),
                  Text(_fmt(_duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ctrl(Icons.skip_previous, widget.onPrev),
                  _ctrl(Icons.replay_10, () => _skip(-10)),
                  GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50914),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 34),
                    ),
                  ),
                  _ctrl(Icons.forward_10, () => _skip(10)),
                  _ctrl(Icons.skip_next, widget.onNext),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.volume_down, color: Colors.white54, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      ),
                      child: Slider(
                        value: _muted ? 0 : _volume,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        onChanged: _setVolume,
                      ),
                    ),
                  ),
                  Text('${_speed}x', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctrl(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: onTap == null ? Colors.white24 : Colors.white, size: 28),
    );
  }

  void _speedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Playback speed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in speeds)
                    ChoiceChip(
                      label: Text('${s}x'),
                      selected: _speed == s,
                      selectedColor: const Color(0xFFE50914),
                      onSelected: (_) {
                        _setSpeed(s);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
