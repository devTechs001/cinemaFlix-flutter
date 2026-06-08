import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  StreamSubscription? _timerSubscription;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  int get totalCount => _notifications.length;

  NotificationService() {
    _notifications = List.from(sampleNotifications);
    _unreadCount = _notifications.where((n) => !n.read).length;
    _simulateLiveNotifications();
  }

  void _simulateLiveNotifications() {
    _timerSubscription = Stream.periodic(const Duration(seconds: 30), (i) => i).listen((_) {
      final newNotif = AppNotification(
        id: 'live_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Live Activity',
        body: '${_randomChatter()} is discussing "${_randomMovie()}" in the Live Room',
        time: 'just now',
        type: NotificationType.live,
      );
      _notifications.insert(0, newNotif);
      _unreadCount++;
      notifyListeners();
    });
  }

  String _randomChatter() {
    const names = ['Sarah J.', 'Mike Chen', 'Alex T.', 'Rachel K.', 'Emma W.', 'James B.'];
    return names[DateTime.now().millisecond % names.length];
  }

  String _randomMovie() {
    const movies = ['Dune', 'Inception', 'The Batman', 'Interstellar', 'Oppenheimer', 'Deadpool'];
    return movies[DateTime.now().second % movies.length];
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
    super.dispose();
  }
}
