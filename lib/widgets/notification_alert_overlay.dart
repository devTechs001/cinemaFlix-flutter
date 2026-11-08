import 'package:flutter/material.dart';
import '../services/globals.dart';

class NotificationAlertOverlay extends StatefulWidget {
  final Widget child;
  const NotificationAlertOverlay({super.key, required this.child});

  @override
  State<NotificationAlertOverlay> createState() => _NotificationAlertOverlayState();
}

class _NotificationAlertOverlayState extends State<NotificationAlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    notificationService.addListener(_onAlert);
  }

  @override
  void dispose() {
    notificationService.removeListener(_onAlert);
    _controller.dispose();
    super.dispose();
  }

  void _onAlert() {
    if (notificationService.currentAlert != null) {
      _controller.forward();
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ListenableBuilder(
          listenable: notificationService,
          builder: (context, _) {
            final alert = notificationService.currentAlert;
            if (alert == null) return const SizedBox.shrink();
            return Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: SlideTransition(
                position: _slide,
                child: GestureDetector(
                  onTap: () {
                    notificationService.dismissAlert();
                    alert.onTap?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 16, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: alert.color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(alert.icon, style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(alert.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(alert.body, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => notificationService.dismissAlert(),
                          child: Icon(Icons.close, color: Colors.white.withAlpha(80), size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
