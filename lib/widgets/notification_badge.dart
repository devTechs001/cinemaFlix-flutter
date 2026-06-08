import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.color = const Color(0xFFE50914),
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF141414), width: 1.5),
      ),
    );
  }
}
