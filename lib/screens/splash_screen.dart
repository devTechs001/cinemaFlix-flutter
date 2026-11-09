import 'dart:math';
import 'package:flutter/material.dart';
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
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _loadingDotsController;
  late Animation<double> _subtitleFade;

  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    soundService.initialize().then((_) => soundService.playAsset(SoundService.bootAsset));

    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speed: 0.002 + _random.nextDouble() * 0.004,
        opacity: 0.2 + _random.nextDouble() * 0.5,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadingDotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (devService.maintenanceMode) {
      Navigator.pushReplacementNamed(context, '/maintenance');
      return;
    }
    // Show the preference onboarding only ONCE (one-time onboarding display).
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;
    Navigator.pushReplacementNamed(context, seenOnboarding ? '/main' : '/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _loadingDotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: AnimatedBuilder(
        animation: Listenable.merge([_particleController, _glowController, _loadingDotsController]),
        builder: (context, _) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2 + _glowController.value * 0.1,
                colors: [
                  Color.lerp(
                    const Color(0xFF2D0A0A),
                    const Color(0xFF1A0000),
                    _glowController.value,
                  )!,
                  const Color(0xFF141414),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Netflix-style drifting movie-card wall (background)
                const MovieCardWall(opacity: 0.42),
                ..._particles.map((p) => _buildParticle(p)),
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) {
                    return Center(
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE50914).withAlpha(
                                (80 + (_glowController.value * 60)).toInt(),
                              ),
                              blurRadius: 30 + _glowController.value * 20,
                              spreadRadius: 5 + _glowController.value * 10,
                            ),
                          ],
                        ),
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: ScaleTransition(
                            scale: _scale,
                            child: const AppLogo(size: 80),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.22,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Your Movie World',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Loading',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      AnimatedBuilder(
                        animation: _loadingDotsController,
                        builder: (context, _) {
                          return Text(
                            List.generate(
                              3,
                              (i) => (_loadingDotsController.value * 3).floor() >= i + 1 ? '.' : ' ',
                            ).join(),
                            style: const TextStyle(
                              color: Color(0xFFE50914),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Text(
                    'v1.0',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 11, letterSpacing: 2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticle(_Particle p) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        final yPos = (p.y + _particleController.value * p.speed) % 1.0;
        return Positioned(
          left: p.x * MediaQuery.of(context).size.width,
          top: yPos * MediaQuery.of(context).size.height,
          child: Container(
            width: p.size,
            height: p.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha((p.opacity * 255).toInt()),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
