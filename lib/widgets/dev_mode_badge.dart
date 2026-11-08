import 'package:flutter/material.dart';

import '../services/globals.dart';

/// Small "DEV MODE" chip shown in headers once dev mode is active.
/// Renders nothing (zero space) while dev mode is off.
class DevModeBadge extends StatelessWidget {
  const DevModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: devService,
      builder: (context, _) {
        if (!devService.devModeEnabled) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFFB300), width: 0.8),
          ),
          child: const Text(
            'DEV MODE',
            style: TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        );
      },
    );
  }
}
