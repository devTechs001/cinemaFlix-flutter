import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class InAppAlert {
  final String id;
  final String title;
  final String body;
  final String icon;
  final Color color;
  final VoidCallback? onTap;

  InAppAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class NotificationService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  StreamSubscription? _timerSubscription;
  int _unreadCount = 0;
  InAppAlert? _currentAlert;
  Timer? _alertTimer;
  RealtimeChannel? _chatChannel;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get totalCount => _notifications.length;
  InAppAlert? get currentAlert => _currentAlert;

  NotificationService() {
    _notifications = List.from(sampleNotifications);
    _unreadCount = _notifications.where((n) => !n.read).length;
    _simulateLiveNotifications();
    _subscribeToChatActivity();
  }

  /// Real-time notifications from other users' chat messages (Supabase
  /// Realtime on `public.messages`). Complements the random popups above.
  void _subscribeToChatActivity() {
    final supa = SupabaseService();
    if (!supa.isInitialized) return;
    try {
      _chatChannel = supa.channel('public:chat-activity')
        ..onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final sender = row['user_id']?.toString() ?? '';
            final myId = supa.auth.currentUser?.id;
            if (sender.isNotEmpty && sender == myId) return;
            final content = (row['content'] ?? '').toString();
            if (content.isEmpty) return;
            final id = 'chat_${row['id'] ?? DateTime.now().millisecondsSinceEpoch}';
            if (_notifications.any((n) => n.id == id)) return;
            final body =
                content.length > 60 ? '${content.substring(0, 60)}…' : content;
            _addNotification(AppNotification(
              id: id,
              title: '${(row['username'] ?? 'Someone')} sent a message',
              body: body,
              time: 'just now',
              type: NotificationType.chat,
            ));
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('NotificationService: chat activity subscription failed: $e');
    }
  }

  void _simulateLiveNotifications() {
    _timerSubscription = Stream.periodic(const Duration(seconds: 30), (i) => i).listen((_) {
      _addNotification(AppNotification(
        id: 'live_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Live Activity',
        body: '${_randomItem(_chatters)} is discussing "${_randomItem(_movies)}" in the Live Room',
        time: 'just now',
        type: NotificationType.live,
      ));
    });
  }

  static const _chatters = ['Sarah J.', 'Mike Chen', 'Alex T.', 'Rachel K.', 'Emma W.', 'James B.'];
  static const _movies = ['Dune', 'Inception', 'The Batman', 'Interstellar', 'Oppenheimer', 'Deadpool'];

  String _randomItem(List<String> items) => items[DateTime.now().millisecond % items.length];

  void _addNotification(AppNotification n) {
    _notifications.insert(0, n);
    _unreadCount++;
    notifyListeners();
  }

  void notifyUpdate({required String version, VoidCallback? onTap}) {
    showAlert(
      title: 'Update v$version ready',
      body: 'Tap to download and install CinemaFlix',
      icon: '⬇️',
      color: const Color(0xFFE50914),
      onTap: onTap,
    );
    _addNotification(AppNotification(
      id: 'update_$version',
      title: 'CinemaFlix v$version',
      body: 'A new build is ready. Open Install & Host to download.',
      time: 'just now',
      type: NotificationType.system,
      route: '/install',
    ));
  }

  void notifyWallet({required String title, required String body, VoidCallback? onTap}) {
    showAlert(
      title: title,
      body: body,
      icon: '💎',
      color: const Color(0xFFFFD700),
      onTap: onTap,
    );
    _addNotification(AppNotification(
      id: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      time: 'just now',
      type: NotificationType.system,
      route: '/wallet',
    ));
  }

  void notifyCreator({required String title, required String body}) {
    showAlert(
      title: title,
      body: body,
      icon: '🎬',
      color: const Color(0xFFE50914),
    );
    _addNotification(AppNotification(
      id: 'creator_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      time: 'just now',
      type: NotificationType.review,
      route: '/creator-hub',
    ));
  }

  void notifyDownload({required String title, required String body, VoidCallback? onTap}) {
    showAlert(
      title: title,
      body: body,
      icon: '📦',
      color: const Color(0xFF1E88E5),
      onTap: onTap,
    );
  }

  void showAlert({required String title, required String body, required String icon, required Color color, VoidCallback? onTap}) {
    _currentAlert = InAppAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      icon: icon,
      color: color,
      onTap: onTap,
    );
    notifyListeners();
    _alertTimer?.cancel();
    _alertTimer = Timer(const Duration(seconds: 5), () {
      _currentAlert = null;
      notifyListeners();
    });
  }

  void dismissAlert() {
    _currentAlert = null;
    _alertTimer?.cancel();
    notifyListeners();
  }

  Future<void> showStorageAlert(StorageAlertLevel level) async {
    final (title, icon, color) = switch (level) {
      StorageAlertLevel.critical => ('Storage Critical', '🚨', const Color(0xFFE50914)),
      StorageAlertLevel.warning => ('Storage Low', '⚠️', const Color(0xFFFF8F00)),
      StorageAlertLevel.ok => ('Storage OK', '✅', const Color(0xFF10B981)),
    };
    showAlert(title: title, body: 'Your device storage is running low. Free up space in Settings.', icon: icon, color: color);
    _addNotification(AppNotification(
      id: 'storage_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: 'Your device storage is running low. Free up space in Settings.',
      time: 'just now',
      type: NotificationType.system,
    ));
  }

  void showConnectivityAlert(bool isOnline, String strength) {
    if (isOnline) {
      showAlert(title: 'Back Online', body: 'Connection restored ($strength)', icon: '📶', color: const Color(0xFF10B981));
      _addNotification(AppNotification(
        id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Back Online',
        body: 'Connection restored ($strength)',
        time: 'just now',
        type: NotificationType.system,
      ));
    } else {
      showAlert(title: 'Disconnected', body: 'No internet connection', icon: '❌', color: const Color(0xFFE50914));
      _addNotification(AppNotification(
        id: 'conn_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Disconnected',
        body: 'No internet connection',
        time: 'just now',
        type: NotificationType.system,
      ));
    }
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
    _chatChannel?.unsubscribe();
    _timerSubscription?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }
}
