import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/globals.dart';
import '../services/sound_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/movie_card_wall.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _intro;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _progress;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _wordmark;
  late Animation<double> _subtitleFade;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  static const _hold = Duration(milliseconds: 4200);

  static const _beats = [
    'Loading posters',
    'Cueing your catalogue',
    'Warming the projector',
    'Almost ready',
  ];

  @override
  void initState() {
    super.initState();
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
    soundService.initialize().then((_) => soundService.playAsset(SoundService.bootAsset));

    for (int i = 0; i < 28; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.4 + _random.nextDouble() * 3.4,
        speed: 0.003 + _random.nextDouble() * 0.008,
        opacity: 0.18 + _random.nextDouble() * 0.55,
        red: _random.nextDouble() > 0.72,
      ));
    }

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.55, curve: Curves.easeOut)),
    );
    _scale = Tween<double>(begin: 0.55, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _wordmark = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: const Interval(0.55, 1.0, curve: Curves.easeIn)),
    );
    _intro.forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _progress = AnimationController(vsync: this, duration: _hold)..forward();

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(_hold);
    if (!mounted) return;
    if (devService.maintenanceMode) {
      Navigator.pushReplacementNamed(context, '/maintenance');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;
    Navigator.pushReplacementNamed(context, seenOnboarding ? '/main' : '/onboarding');
  }

  @override
  void dispose() {
    _intro.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _progress.dispose();
    super.dispose();
  }

  String get _beat {
    var i = (_progress.value * _beats.length).floor();
    if (i < 0) i = 0;
    if (i >= _beats.length) i = _beats.length - 1;
    return _beats[i];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _particleController,
          _glowController,
          _progress,
          _intro,
        ]),
        builder: (context, _) {
          final glow = _glowController.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              const MovieCardWall(
                opacity: 0.62,
                angle: -0.18,
                cardWidth: 104,
                cardHeight: 156,
                duration: Duration(seconds: 16),
                appearDuration: Duration(milliseconds: 1500),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 1.05 + glow * 0.12,
                    colors: [
                      Color.lerp(const Color(0xCC1A0000), const Color(0xAA3B0508), glow)!,
                      const Color(0xE6090909),
                    ],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC000000),
                      Color(0x55000000),
                      Color(0xDD000000),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              ..._particles.map(_buildParticle),
              Center(child: _brand(glow)),
              Positioned(
                left: 36,
                right: 36,
                bottom: 48,
                child: FadeTransition(
                  opacity: _subtitleFade,
                  child: _loadingDock(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _brand(double glow) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withAlpha((70 + glow * 90).toInt()),
                    blurRadius: 36 + glow * 28,
                    spreadRadius: 4 + glow * 10,
                  ),
                ],
              ),
              child: const AppLogo(size: 92, showText: false),
            ),
          ),
        ),
        const SizedBox(height: 22),
        FadeTransition(
          opacity: _wordmark,
          child: Transform.translate(
            offset: Offset(0, (1 - _wordmark.value) * 12),
            child: Column(
              children: [
                Text(
                  'CINEMAFLIX',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4 + (1 - _wordmark.value) * 10,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'YOUR MOVIE WORLD',
                    style: TextStyle(
                      color: Colors.white.withAlpha(170),
                      fontSize: 11,
                      letterSpacing: 4.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingDock() {
    final p = Curves.easeInOut.transform(_progress.value);
    return Column(
      children: [
        Text(
          _beat,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0x33FFFFFF)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: p,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFFF6B6B)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${(p * 100).clamp(0.0, 100.0).round()}%',
          style: TextStyle(
            color: Colors.white.withAlpha(70),
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildParticle(_Particle p) {
    final yPos = (p.y + _particleController.value * p.speed * 18) % 1.0;
    final pulse = 0.55 + 0.45 * sin((_particleController.value + p.x) * pi * 2);
    return Positioned(
      left: p.x * MediaQuery.of(context).size.width,
      top: yPos * MediaQuery.of(context).size.height,
      child: Container(
        width: p.size,
        height: p.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (p.red ? const Color(0xFFE50914) : Colors.white)
              .withAlpha(((p.opacity * pulse * 255).clamp(0.0, 255.0)).round()),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final bool red;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.red,
  });
}
