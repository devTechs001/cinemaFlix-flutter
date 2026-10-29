import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tappable card with a press-scale animation and haptic feedback.
///
/// Accessibility: exposes button semantics to screen readers (pass
/// [semanticLabel] for icon-only cards). Desktop: shows a click cursor
/// on hover.
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration animationDuration;
  final EdgeInsets? margin;

  /// Screen-reader label, recommended for icon-only cards.
  final String? semanticLabel;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.96,
    this.animationDuration = const Duration(milliseconds: 120),
    this.margin,
    this.semanticLabel,
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
      child: Semantics(
        button: widget.onTap != null,
        enabled: widget.onTap != null,
        label: widget.semanticLabel,
        child: MouseRegion(
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
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
        ),
      ),
    );
  }
}
