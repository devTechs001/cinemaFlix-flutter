import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'storage_service.dart';

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

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get totalCount => _notifications.length;
  InAppAlert? get currentAlert => _currentAlert;

  NotificationService() {
    _notifications = List.from(sampleNotifications);
    _unreadCount = _notifications.where((n) => !n.read).length;
    _simulateLiveNotifications();
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
    _timerSubscription?.cancel();
    _alertTimer?.cancel();
    super.dispose();
  }
}
