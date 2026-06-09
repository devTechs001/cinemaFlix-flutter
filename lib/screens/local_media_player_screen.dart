import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';

class LocalMediaPlayerScreen extends StatefulWidget {
  const LocalMediaPlayerScreen({super.key});

  @override
  State<LocalMediaPlayerScreen> createState() => _LocalMediaPlayerScreenState();
}

class _LocalMediaPlayerScreenState extends State<LocalMediaPlayerScreen> {
  String? _path;
  String? _type;
  String? _name;

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
      ),
      body: Center(
        child: _path == null
            ? const Text('No file selected', style: TextStyle(color: Colors.white54))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(20),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      _type == 'video' ? Icons.videocam_rounded
                          : _type == 'audio' ? Icons.audiotrack_rounded
                          : Icons.image_rounded,
                      color: const Color(0xFFE50914),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(_name ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(_path ?? '', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text((_type ?? '').toUpperCase(), style: const TextStyle(color: Color(0xFFE50914), fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 40),
                  if (_type == 'video' || _type == 'audio') ...[
                    Container(
                      width: 300,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.35,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE50914),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('1:23', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                        const SizedBox(width: 200),
                        Text('3:45', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _playerButton(Icons.skip_previous_rounded, 36),
                        const SizedBox(width: 16),
                        Container(
                          width: 56, height: 56,
                          decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        _playerButton(Icons.skip_next_rounded, 36),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: 240, height: 320,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Center(
                        child: Icon(Icons.image_outlined, color: Colors.white.withAlpha(60), size: 64),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  InteractiveCard(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Close Player', style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 14)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _playerButton(IconData icon, double size) {
    return InteractiveCard(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
