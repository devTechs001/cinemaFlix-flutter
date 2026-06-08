import 'package:flutter/foundation.dart';

enum GuestRestriction {
  canWatch,
  canBrowse,
  cannotReview,
  cannotChat,
  cannotDownload,
  limitedQuality,
}

class GuestService extends ChangeNotifier {
  bool _isGuest = false;
  String _guestId = '';
  final Set<GuestRestriction> _restrictions = {};
  int _sessionViews = 0;

  bool get isGuest => _isGuest;
  String get guestId => _guestId;
  int get sessionViews => _sessionViews;
  Set<GuestRestriction> get restrictions => Set.unmodifiable(_restrictions);

  bool get canWatch => !_restrictions.contains(GuestRestriction.canWatch);
  bool get canBrowse => !_restrictions.contains(GuestRestriction.canBrowse);
  bool get canReview => !_restrictions.contains(GuestRestriction.cannotReview);
  bool get canChat => !_restrictions.contains(GuestRestriction.cannotChat);
  bool get canDownload => !_restrictions.contains(GuestRestriction.cannotDownload);
  bool get isHD => !_restrictions.contains(GuestRestriction.limitedQuality);

  void startGuestSession() {
    _isGuest = true;
    _guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    _restrictions.addAll([
      GuestRestriction.cannotReview,
      GuestRestriction.cannotChat,
      GuestRestriction.cannotDownload,
      GuestRestriction.limitedQuality,
    ]);
    _sessionViews = 0;
    notifyListeners();
  }

  void incrementViews() {
    _sessionViews++;
    if (_sessionViews >= 5) {
      _restrictions.add(GuestRestriction.canWatch);
      notifyListeners();
    }
  }

  Future<void> upgradeToFull() async {
    _isGuest = false;
    _restrictions.clear();
    _guestId = '';
    notifyListeners();
  }

  void endGuestSession() {
    _isGuest = false;
    _restrictions.clear();
    _guestId = '';
    _sessionViews = 0;
    notifyListeners();
  }
}
