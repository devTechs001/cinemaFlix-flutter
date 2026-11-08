import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';

enum RepeatMode { none, one, all }
enum AspectRatioMode { auto, wide, full, original }

class _EqualizerPreset {
  final String name;
  final IconData icon;
  final List<double> bands;
  _EqualizerPreset(this.name, this.icon, this.bands);
}

class LocalMediaPlayerScreen extends StatefulWidget {
  const LocalMediaPlayerScreen({super.key});

  @override
  State<LocalMediaPlayerScreen> createState() => _LocalMediaPlayerScreenState();
}

class _LocalMediaPlayerScreenState extends State<LocalMediaPlayerScreen> {
  String? _path;
  String? _type;
  String? _name;
  bool _playing = false;
  bool _shuffle = false;
  RepeatMode _repeat = RepeatMode.none;
  double _volume = 0.8;
  double _brightness = 1.0;
  double _playbackSpeed = 1.0;
  int _qualityIndex = 4;
  int _eqPresetIndex = 0;
  int _currentTimeSec = 83;
  int _durationSec = 225;
  AspectRatioMode _aspectRatio = AspectRatioMode.auto;
  bool _showControls = true;

  static const _qualities = ['Auto', '144p', '240p', '360p', '480p', '720p', '1080p', '4K'];

  static final _eqPresets = [
    _EqualizerPreset('Normal', Icons.tune, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    _EqualizerPreset('Classical', Icons.music_note, [-1, -1, 0, 0, 2, 3, 4, 3, 1, 0]),
    _EqualizerPreset('Dance', Icons.auto_awesome, [4, 3, 2, 1, 0, -1, -1, 0, 1, 2]),
    _EqualizerPreset('Bass Boost', Icons.equalizer, [6, 5, 4, 2, 0, -1, -2, -2, -1, 0]),
    _EqualizerPreset('Rock', Icons.rocket, [3, 2, 1, 0, -1, -1, 0, 1, 2, 3]),
    _EqualizerPreset('Jazz', Icons.piano, [2, 1, 0, 1, 2, 3, 2, 1, 0, -1]),
    _EqualizerPreset('Pop', Icons.star, [-1, 0, 1, 2, 3, 2, 1, 0, -1, -1]),
    _EqualizerPreset('Vocal', Icons.mic, [-1, 0, 1, 2, 3, 2, 1, 0, -1, -2]),
    _EqualizerPreset('Flat', Icons.horizontal_rule, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
  ];

  static const _bandLabels = ['32', '64', '125', '250', '500', '1K', '2K', '4K', '8K', '16K'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _path == null) {
      _path = args['path'] as String?;
      _type = args['type'] as String?;
      _name = args['name'] as String?;
    }
  }

  String get _timeStr {
    final m = (_currentTimeSec ~/ 60).toString().padLeft(2, '0');
    final s = (_currentTimeSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _durationStr {
    final m = (_durationSec ~/ 60).toString().padLeft(2, '0');
    final s = (_durationSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => _durationSec > 0 ? _currentTimeSec / _durationSec : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_name ?? 'Media Player', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_type == 'audio')
            _appBarIcon(Icons.equalizer, _showEqualizerSheet),
          _appBarIcon(Icons.speed, _showSpeedSheet),
          _appBarIcon(Icons.more_vert, _showMoreOptions),
        ],
      ),
      body: _path == null
          ? const Center(child: Text('No file selected', style: TextStyle(color: Colors.white54)))
          : GestureDetector(
              onTap: () => setState(() => _showControls = !_showControls),
              child: Column(
                children: [
                  Expanded(
                    child: _type == 'video'
                        ? _buildVideoArea()
                        : _type == 'audio'
                            ? _buildAudioArea()
                            : _buildImageArea(),
                  ),
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildControls(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _appBarIcon(IconData icon, VoidCallback onTap) {
    return InteractiveCard(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildVideoArea() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 260,
              color: const Color(0xFF0A0A0A),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Center(
                      child: Icon(Icons.videocam_rounded, color: Colors.white.withAlpha(30), size: 80),
                    ),
                  ),
                  if (!_playing)
                    GestureDetector(
                      onTap: () => setState(() => _playing = true),
                      child: Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_qualities[_qualityIndex], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _captionChip('HDR', const Color(0xFFE50914)),
                  const SizedBox(width: 6),
                  _captionChip(_qualities[_qualityIndex], const Color(0xFF1E88E5)),
                  const SizedBox(width: 6),
                  _captionChip('${_playbackSpeed}x', const Color(0xFFFF8F00)),
                  const Spacer(),
                  _captionChip(_aspectRatio.name.toUpperCase(), Colors.white38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _captionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withAlpha(60))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAudioArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFE50914).withAlpha(40), width: 2),
            ),
            child: Center(
              child: Icon(
                _playing ? Icons.audiotrack_rounded : Icons.play_arrow_rounded,
                color: const Color(0xFFE50914),
                size: 72,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(_name ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Device Audio', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 13)),
          const SizedBox(height: 20),
          _buildVisualizer(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(20), borderRadius: BorderRadius.circular(6)),
            child: Text('${_eqPresets[_eqPresetIndex].name} EQ', style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizer() {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(24, (i) {
          final height = _playing ? (10.0 + math.sin(i * 3.14) * 15 + math.cos(i * 1.7) * 10).clamp(4.0, 36.0) : 8.0;
          return Container(
            width: 3,
            height: height.toDouble(),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE50914).withAlpha((100 + (i * 6) % 155).toInt()),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildImageArea() {
    return Center(
      child: Container(
        width: 280, height: 360,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.white.withAlpha(60), size: 80),
            const SizedBox(height: 16),
            Text(_name ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text('${_qualities[_qualityIndex]} • ${_aspectRatio.name.toUpperCase()}', style: const TextStyle(color: Color(0xFFE50914), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 8, top: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withAlpha(0), Colors.black.withAlpha(220)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: const Color(0xFFE50914),
              inactiveTrackColor: const Color(0xFF2A2A2A),
              thumbColor: const Color(0xFFE50914),
              overlayColor: const Color(0xFFE50914).withAlpha(30),
            ),
            child: Slider(
              value: _progress.clamp(0.0, 1.0),
              onChanged: (v) => setState(() => _currentTimeSec = (v * _durationSec).toInt()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(_timeStr, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
                const Spacer(),
                Text(_durationStr, style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallCtrl(Icons.shuffle, _shuffle ? const Color(0xFFE50914) : Colors.white54, () => setState(() => _shuffle = !_shuffle)),
              const SizedBox(width: 12),
              _smallCtrl(Icons.skip_previous_rounded, Colors.white, () {}),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _playing = !_playing),
                child: Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                  child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(width: 16),
              _smallCtrl(Icons.skip_next_rounded, Colors.white, () {}),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _repeat = _repeat == RepeatMode.none ? RepeatMode.one
                        : _repeat == RepeatMode.one ? RepeatMode.all
                        : RepeatMode.none;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _repeat != RepeatMode.none ? const Color(0xFFE50914).withAlpha(25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _repeat == RepeatMode.one ? Icons.repeat_one_rounded
                        : _repeat == RepeatMode.all ? Icons.repeat_rounded
                        : Icons.repeat_rounded,
                    color: _repeat != RepeatMode.none ? const Color(0xFFE50914) : Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _volumeSlider(),
              const SizedBox(width: 12),
              if (_type == 'video') _brightnessSlider(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallCtrl(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _volumeSlider() {
    return Expanded(
      child: Row(
        children: [
          Icon(Icons.volume_down_rounded, color: Colors.white.withAlpha(120), size: 16),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white.withAlpha(120),
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withAlpha(20),
              ),
              child: Slider(value: _volume, onChanged: (v) => setState(() => _volume = v)),
            ),
          ),
          Icon(Icons.volume_up_rounded, color: Colors.white.withAlpha(120), size: 16),
        ],
      ),
    );
  }

  Widget _brightnessSlider() {
    return Expanded(
      child: Row(
        children: [
          Icon(Icons.brightness_low, color: Colors.white.withAlpha(120), size: 16),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: Colors.white.withAlpha(120),
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withAlpha(20),
              ),
              child: Slider(value: _brightness, onChanged: (v) => setState(() => _brightness = v)),
            ),
          ),
          Icon(Icons.brightness_high, color: Colors.white.withAlpha(120), size: 16),
        ],
      ),
    );
  }

  void _showQualitySheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.hd, color: Color(0xFFE50914), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Video Quality', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ..._qualities.asMap().entries.map((e) {
              final active = e.key == _qualityIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InteractiveCard(
                  onTap: () { setState(() => _qualityIndex = e.key); Navigator.pop(ctx); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE50914).withAlpha(20) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? const Color(0xFFE50914).withAlpha(80) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? const Color(0xFFE50914) : Colors.white38, size: 18),
                        const SizedBox(width: 12),
                        Text(e.value, style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: active ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
                        const Spacer(),
                        Text(['Auto (Recommended)', 'Lowest', 'Low', 'Medium', 'Standard', 'High', 'Very High', 'Ultra HD'][e.key], style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showEqualizerSheet() {
    HapticFeedback.mediumImpact();
    final bands = _eqPresets[_eqPresetIndex].bands;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.equalizer, color: Color(0xFFE50914), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Equalizer', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(25), borderRadius: BorderRadius.circular(6)),
                    child: Text(_eqPresets[_eqPresetIndex].name, style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(10, (i) {
                          final val = bands[i];
                          final barHeight = ((val + 6) / 12 * 160).clamp(8.0, 160.0);
                          return Expanded(
                            child: GestureDetector(
                              onVerticalDragUpdate: (details) {
                                final dy = details.localPosition.dy;
                                final newVal = ((1 - dy / 200) * 12 - 6).clamp(-6.0, 6.0);
                                final newBands = List<double>.from(bands);
                                newBands[i] = double.parse(newVal.toStringAsFixed(1));
                                setSheetState(() { _eqPresets[_eqPresetIndex] = _EqualizerPreset(_eqPresets[_eqPresetIndex].name, _eqPresets[_eqPresetIndex].icon, newBands); });
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(val.toStringAsFixed(1), style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 8)),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: double.infinity,
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: val > 0 ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_bandLabels[i], style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 8)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _eqPresets.asMap().entries.map((e) {
                    final active = e.key == _eqPresetIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InteractiveCard(
                        onTap: () {
                          setSheetState(() => _eqPresetIndex = e.key);
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(e.value.icon, color: active ? Colors.white : Colors.white54, size: 12),
                              const SizedBox(width: 4),
                              Text(e.value.name, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpeedSheet() {
    HapticFeedback.mediumImpact();
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 4.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.speed, color: Color(0xFFE50914), size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Playback Speed', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: speeds.map((s) {
                final active = s == _playbackSpeed;
                return InteractiveCard(
                  onTap: () { setState(() => _playbackSpeed = s); Navigator.pop(ctx); },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 72) / 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? const Color(0xFFE50914) : Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text('${s}x', style: TextStyle(color: active ? Colors.white : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (s == 1.0)
                          Text('Normal', style: TextStyle(color: active ? Colors.white.withAlpha(180) : Colors.white38, fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('More Options', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _optionTile(Icons.hd, 'Quality', _qualities[_qualityIndex], _showQualitySheet),
            if (_type == 'audio') _optionTile(Icons.equalizer, 'Equalizer', _eqPresets[_eqPresetIndex].name, _showEqualizerSheet),
            _optionTile(Icons.speed, 'Speed', '${_playbackSpeed}x', _showSpeedSheet),
            _optionTile(
              _aspectRatio == AspectRatioMode.auto ? Icons.aspect_ratio : Icons.crop_original,
              'Aspect Ratio',
              _aspectRatio.name.toUpperCase(),
              () { Navigator.pop(ctx); _showAspectRatioSheet(); },
            ),
            _optionTile(
              _repeat == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
              'Repeat',
              _repeat == RepeatMode.none ? 'Off' : _repeat == RepeatMode.one ? 'One' : 'All',
              () { Navigator.pop(ctx); setState(() { _repeat = _repeat == RepeatMode.none ? RepeatMode.one : _repeat == RepeatMode.one ? RepeatMode.all : RepeatMode.none; }); },
            ),
            _optionTile(Icons.shuffle, 'Shuffle', _shuffle ? 'On' : 'Off', () { Navigator.pop(ctx); setState(() => _shuffle = !_shuffle); }),
          ],
        ),
      ),
    );
  }

  void _showAspectRatioSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aspect Ratio', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...AspectRatioMode.values.map((mode) {
              final active = mode == _aspectRatio;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InteractiveCard(
                  onTap: () { setState(() => _aspectRatio = mode); Navigator.pop(ctx); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFE50914).withAlpha(20) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? const Color(0xFFE50914).withAlpha(80) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Icon(active ? Icons.check_circle : Icons.circle_outlined, color: active ? const Color(0xFFE50914) : Colors.white38, size: 18),
                        const SizedBox(width: 12),
                        Text(mode.name.toUpperCase(), style: TextStyle(color: active ? Colors.white : Colors.white54, fontWeight: active ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InteractiveCard(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white54, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(20), borderRadius: BorderRadius.circular(6)),
                child: Text(value, style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
