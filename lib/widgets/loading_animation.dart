import 'package:flutter/material.dart';

class CinemaLoading extends StatefulWidget {
  final String? message;
  final double size;

  const CinemaLoading({super.key, this.message, this.size = 48});

  @override
  State<CinemaLoading> createState() => _CinemaLoadingState();
}

class _CinemaLoadingState extends State<CinemaLoading>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _pulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotateController]),
            builder: (_, __) {
              return Transform.scale(
                scale: _pulse.value,
                child: RotationTransition(
                  turns: _rotateController,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.size * 0.22),
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFFE50914),
                          Color(0xFF7B1FA2),
                          Color(0xFF1E88E5),
                          Color(0xFFE50914),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: widget.size * 0.7,
                        height: widget.size * 0.7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(widget.size * 0.15),
                        ),
                        child: const Icon(Icons.movie_creation_rounded, color: Color(0xFFE50914)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 20),
            Text(
              widget.message!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class CinemaPageLoader extends StatelessWidget {
  const CinemaPageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CinemaLoading(message: 'Loading...'),
    );
  }
}
