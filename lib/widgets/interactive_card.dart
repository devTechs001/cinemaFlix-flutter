import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration animationDuration;
  final EdgeInsets? margin;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.96,
    this.animationDuration = const Duration(milliseconds: 120),
    this.margin,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleAmount)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) {
          HapticFeedback.lightImpact();
          _controller.forward();
        } : null,
        onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }
}
