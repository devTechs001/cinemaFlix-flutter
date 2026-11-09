import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_config.dart';
import '../services/backend_api_service.dart';

/// "real_me bridge" card shown on the Live screen: live connection
/// status to the CinemaFlix backend, open-room count, and a copyable
/// bridge endpoint for the companion real_me app.
class RealMeBridge extends StatefulWidget {
  const RealMeBridge({super.key});

  @override
  State<RealMeBridge> createState() => _RealMeBridgeState();
}

class _RealMeBridgeState extends State<RealMeBridge> {
  bool? _backendUp;
  int? _rooms;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final up = await BackendApiService.checkHealth();
    int? rooms;
    if (up) {
      try {
        rooms = (await BackendApiService.getLiveRooms())?.length;
      } catch (_) {
        rooms = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _backendUp = up;
      _rooms = rooms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C2BD9).withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C2BD9).withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6C2BD9).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.live_tv_rounded, color: Color(0xFFB388FF), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'real_me bridge',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(state: _backendUp),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _rooms == null
                      ? 'Rooms mirror to the real_me companion app.'
                      : '$_rooms room(s) maintained for real_me · kept alive by host heartbeats',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Copy bridge endpoint',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: ApiConfig.baseUrl));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bridge endpoint copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
          ),
          IconButton(
            tooltip: 'Refresh status',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool? state;

  const _StatusChip({this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      true => ('connected', const Color(0xFF43A047)),
      false => ('offline', Colors.white38),
      null => ('connecting…', const Color(0xFFFFB300)),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}
