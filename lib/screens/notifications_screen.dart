import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/interactive_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _notificationService.removeListener(_onChange);
    _notificationService.dispose();
    super.dispose();
  }

  List<AppNotification> get _filtered {
    if (_filter == 'All') return _notificationService.notifications;
    final type = _filter == 'Movies' ? NotificationType.movie
        : _filter == 'Chat' ? NotificationType.chat
        : _filter == 'Live' ? NotificationType.live
        : NotificationType.system;
    return _notificationService.notifications.where((n) => n.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_notificationService.unreadCount > 0)
            InteractiveCard(
              onTap: () {
                HapticFeedback.mediumImpact();
                _notificationService.markAllAsRead();
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Mark all read', style: TextStyle(color: Color(0xFFE50914), fontSize: 13)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.white.withAlpha(40)),
                        const SizedBox(height: 16),
                        const Text('No notifications', style: TextStyle(color: Colors.white38, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const Divider(color: Color(0xFF2A2A2A), height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final notif = _filtered[index];
                      return InteractiveCard(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _notificationService.markAsRead(notif.id);
                        },
                        child: ListTile(
                          leading: _buildIcon(notif.type, notif.read),
                          title: Row(
                            children: [
                              Text(notif.title, style: TextStyle(
                                color: Colors.white,
                                fontWeight: notif.read ? FontWeight.normal : FontWeight.w600,
                                fontSize: 14,
                              )),
                              if (!notif.read) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFFE50914), shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(notif.body, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Text(notif.time, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = ['All', 'Movies', 'Chat', 'Live', 'System'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final active = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InteractiveCard(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _filter = f);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE50914) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(f, style: TextStyle(
                    color: active ? Colors.white : Colors.white54,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  )),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type, bool read) {
    final alpha = read ? 60 : 100;
    switch (type) {
      case NotificationType.movie:
        return Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFE50914).withAlpha(alpha), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.movie_outlined, color: Color(0xFFE50914), size: 22),
        );
      case NotificationType.chat:
        return Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFF7B1FA2).withAlpha(alpha), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.chat_outlined, color: Color(0xFF7B1FA2), size: 22),
        );
      case NotificationType.live:
        return Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFF1E88E5).withAlpha(alpha), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.live_tv_outlined, color: Color(0xFF1E88E5), size: 22),
        );
      case NotificationType.review:
        return Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFFF8F00).withAlpha(alpha), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.star_outline, color: Color(0xFFFF8F00), size: 22),
        );
      case NotificationType.system:
        return Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFF43A047).withAlpha(alpha), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.settings_outlined, color: Color(0xFF43A047), size: 22),
        );
    }
  }
}
