import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cinemaflix/services/device_service.dart';
import 'package:cinemaflix/widgets/interactive_card.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  @override
  void initState() {
    super.initState();
    deviceService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deviceService,
      builder: (context, _) {
        final devices = deviceService.devices;
        final onlineCount = devices.where((d) => d.isOnline).length;
        return Scaffold(
          backgroundColor: const Color(0xFF141414),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1F1F1F),
            title: const Text('Connected Devices', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF6366F1).withAlpha(60), const Color(0xFF8B5CF6).withAlpha(40)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.devices, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Devices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('$onlineCount online • ${devices.length} total', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: onlineCount > 0 ? const Color(0xFF10B981).withAlpha(30) : Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: onlineCount > 0 ? const Color(0xFF10B981) : Colors.white38, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(onlineCount > 0 ? 'Online' : 'Offline', style: TextStyle(color: onlineCount > 0 ? const Color(0xFF10B981) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('All Devices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              ...devices.map((d) => _deviceCard(d)),
              const SizedBox(height: 20),
              const Text('Real-Time Sync', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _syncRow(Icons.wifi, 'Auto-Sync', 'Devices sync every 30s'),
                    const Divider(color: Color(0xFF2A2A2A), height: 20),
                    _syncRow(Icons.cloud_done, 'Watch History', 'Synced across devices'),
                    const Divider(color: Color(0xFF2A2A2A), height: 20),
                    _syncRow(Icons.favorite, 'Favorites', 'Synced across devices'),
                    const Divider(color: Color(0xFF2A2A2A), height: 20),
                    _syncRow(Icons.settings_backup_restore, 'Settings', 'Synced across devices'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InteractiveCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF1F1F1F),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (ctx) => SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(height: 16),
                            const Text('Simulate Device', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildSimulateOption('Samsung Galaxy S25', 'Android'),
                            _buildSimulateOption('iPhone 17 Pro', 'iOS'),
                            _buildSimulateOption('MacBook Pro M4', 'macOS'),
                            _buildSimulateOption('Windows PC', 'Windows'),
                            _buildSimulateOption('iPad Pro', 'iPadOS'),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
                  ),
                  child: const Center(
                    child: Text('+ Simulate Device Connection', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _deviceCard(DeviceInfo d) {
    final platformIcon = _platformIcon(d.platform);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: d.isOnline ? const Color(0xFF10B981).withAlpha(25) : Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(platformIcon, color: d.isOnline ? const Color(0xFF10B981) : Colors.white38, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    if (d.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF6366F1).withAlpha(30), borderRadius: BorderRadius.circular(6)),
                        child: const Text('This device', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: d.isOnline ? const Color(0xFF10B981) : Colors.white38, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(d.isOnline ? 'Online' : 'Last seen ${_timeAgo(d.lastSeen)}', style: TextStyle(color: d.isOnline ? const Color(0xFF10B981) : Colors.white38, fontSize: 12)),
                    const SizedBox(width: 12),
                    Text(d.platform, style: const TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (!d.isCurrent)
            InteractiveCard(
              onTap: () => _confirmRemove(d.id, d.name),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.close, color: Colors.white38, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'Android': return Icons.android;
      case 'iOS': return Icons.apple;
      case 'macOS': return Icons.laptop_mac;
      case 'Windows': return Icons.laptop_windows;
      case 'iPadOS': return Icons.tablet_mac;
      case 'linux': return Icons.terminal;
      default: return Icons.devices;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _syncRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
              Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
      ],
    );
  }

  void _confirmRemove(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Device', style: TextStyle(color: Colors.white)),
        content: Text('Remove $name from connected devices?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              deviceService.removeDevice(id);
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulateOption(String name, String platform) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InteractiveCard(
        onTap: () {
          deviceService.simulateDeviceConnected(name, platform);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name connected'), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(_platformIcon(platform), color: Colors.white70, size: 24),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(platform, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
