import 'dart:async';
import 'package:flutter/foundation.dart';

class CacheInfo {
  final double videoCache;
  final double imageCache;
  final double thumbnails;
  final double searchHistory;

  double get total => videoCache + imageCache + thumbnails + searchHistory;

  const CacheInfo({
    this.videoCache = 0.8,
    this.imageCache = 0.4,
    this.thumbnails = 0.2,
    this.searchHistory = 0.05,
  });
}

class CacheService extends ChangeNotifier {
  bool _isClearing = false;
  double _progress = 0.0;
  CacheInfo _cacheInfo = CacheInfo();

  bool get isClearing => _isClearing;
  double get progress => _progress;
  CacheInfo get cacheInfo => _cacheInfo;

  Future<void> clearAll({bool video = true, bool images = true, bool thumbnails = true, bool history = true}) async {
    if (_isClearing) return;
    _isClearing = true;
    _progress = 0.0;
    notifyListeners();

    final steps = [video, images, thumbnails, history].where((s) => s).length;
    var completed = 0;

    if (video) {
      for (var i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        _progress = (completed + i / 10) / steps;
        notifyListeners();
      }
      completed++;
    }

    if (images) {
      for (var i = 0; i <= 8; i++) {
        await Future.delayed(const Duration(milliseconds: 80));
        _progress = (completed + i / 8) / steps;
        notifyListeners();
      }
      completed++;
    }

    if (thumbnails) {
      await Future.delayed(const Duration(milliseconds: 400));
      _progress = (completed + 0.5) / steps;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));
      _progress = ++completed / steps;
      notifyListeners();
    }

    if (history) {
      await Future.delayed(const Duration(milliseconds: 200));
      _progress = ++completed / steps;
      notifyListeners();
    }

    _cacheInfo = CacheInfo(
      videoCache: video ? 0 : _cacheInfo.videoCache,
      imageCache: images ? 0 : _cacheInfo.imageCache,
      thumbnails: thumbnails ? 0 : _cacheInfo.thumbnails,
      searchHistory: history ? 0 : _cacheInfo.searchHistory,
    );

    _isClearing = false;
    _progress = 1.0;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _progress = 0.0;
    notifyListeners();
  }

  Future<void> refreshCacheInfo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cacheInfo = CacheInfo(
      videoCache: (0.2 + (_cacheInfo.videoCache * 0.8)),
      imageCache: (0.1 + (_cacheInfo.imageCache * 0.8)),
      thumbnails: (0.05 + (_cacheInfo.thumbnails * 0.8)),
      searchHistory: (0.01 + (_cacheInfo.searchHistory * 0.8)),
    );
    notifyListeners();
  }
}
