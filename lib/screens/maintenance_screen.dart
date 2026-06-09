import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/interactive_card.dart';
import '../services/globals.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  @override
  void initState() {
    super.initState();
    _pollMaintenanceStatus();
  }

  void _pollMaintenanceStatus() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !devService.maintenanceMode) {
        Navigator.pushReplacementNamed(context, '/auth');
      } else if (mounted) {
        _pollMaintenanceStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withAlpha(20),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.construction, color: Color(0xFFE50914), size: 52),
              ),
              const SizedBox(height: 32),
              const Text(
                'Under Maintenance',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'CinemaFlix is currently undergoing scheduled maintenance.\nWe\'ll be back shortly!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              const _MaintenanceProgress(),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Color(0xFFFFA000), shape: BoxShape.circle),
                          child: Center(
                            child: SizedBox(
                              width: 4, height: 4,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFFFFA000).withAlpha(120),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Estimated time remaining:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('~ 30 minutes', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              InteractiveCard(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _pollMaintenanceStatus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white54, size: 18),
                      SizedBox(width: 8),
                      Text('Check Again', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceProgress extends StatefulWidget {
  const _MaintenanceProgress();

  @override
  State<_MaintenanceProgress> createState() => _MaintenanceProgressState();
}

class _MaintenanceProgressState extends State<_MaintenanceProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.3 + (_controller.value * 0.4),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFFF6F00)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
