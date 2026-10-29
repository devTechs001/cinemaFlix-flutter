import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.color = const AppColors.brand,
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
        border: Border.all(color: const AppColors.background, width: 1.5),
      ),
    );
  }
}
