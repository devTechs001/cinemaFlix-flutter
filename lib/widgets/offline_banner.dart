import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class OfflineBanner extends StatefulWidget {
  final ConnectivityService connectivityService;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.connectivityService,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    widget.connectivityService.addListener(_onConnectivityChanged);
    if (!widget.connectivityService.isOnline) {
      _wasOffline = true;
      _slideController.value = 1.0;
    }
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    if (widget.connectivityService.isOnline && _wasOffline) {
      _slideController.reverse();
      _wasOffline = false;
    } else if (!widget.connectivityService.isOnline && !_wasOffline) {
      _slideController.forward();
      _wasOffline = true;
    }
  }

  @override
  void dispose() {
    widget.connectivityService.removeListener(_onConnectivityChanged);
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFE50914),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    widget.connectivityService.checkNow();
                  },
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
