import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

/// In-app notifications.
///
/// Seeded with a few starter notifications, then driven by **real**
/// activity: new community chat messages from other users arrive over
/// Supabase Realtime and become notifications here. (The previous
/// version invented a fake notification every 30 seconds.)
class NotificationService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  List<AppNotification> _notifications = [];
  RealtimeChannel? _channel;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get totalCount => _notifications.length;

  NotificationService() {
    _notifications = List.from(sampleNotifications);
    _unreadCount = _notifications.where((n) => !n.read).length;
    _subscribeToChatActivity();
  }

  void _subscribeToChatActivity() {
    if (!_supabase.isInitialized) return;
    _channel = _supabase.channel('notifications:chat')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        table: 'messages',
        callback: (payload) {
          final record = payload.newRecord;
          final myId = _supabase.auth.currentUser?.id;
          final senderId = record['user_id']?.toString();
          if (senderId != null && senderId == myId) return;
          final username = record['username']?.toString() ?? 'Someone';
          final content = record['content']?.toString() ?? '';
          final preview =
              content.length > 60 ? '${content.substring(0, 60)}…' : content;
          _notifications.insert(
            0,
            AppNotification(
              id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
              title: 'New chat message',
              body: '$username: $preview',
              time: 'just now',
              type: NotificationType.chat,
            ),
          );
          _unreadCount++;
          notifyListeners();
        },
      )
      ..subscribe();
  }

  void markAsRead(String id) {
    _notifications = _notifications.map((n) {
      if (n.id == id && !n.read) {
        _unreadCount--;
        return n.copyWith(read: true);
      }
      return n;
    }).toList();
    notifyListeners();
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
