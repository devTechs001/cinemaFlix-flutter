import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'globals.dart';
import 'wallet_service.dart';

/// Ads system — serves banners from the backend /api/ads endpoint, records
/// impressions/clicks and rewards users with wallet points for interaction
/// ("earn from ads" per bugs.txt). [isSubscribed] gates display: paying
/// subscribers skip mid-watch ads; free users see them after a period of
/// watching (see [AdOverlayScheduler]).
class AdsService extends ChangeNotifier {
  List<Map<String, dynamic>> _banners = [];
  bool _enabled = true;
  bool _loading = false;

  List<Map<String, dynamic>> get banners => List.unmodifiable(_banners);
  bool get enabled => _enabled;
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse(ApiConfig.apiPath('/ads'))).timeout(const Duration(seconds: 8));
      final data = (res.body.isEmpty) ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      _banners = List<Map<String, dynamic>>.from((data['ads'] as List?) ?? []);
      if (_banners.isEmpty) _enabled = false;
    } catch (e) {
      debugPrint('AdsService: refresh skipped: $e');
      _banners = [];
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> recordImpression(String adId) async {
    try {
      await http.post(Uri.parse(ApiConfig.apiPath('/ads/$adId/impression'))).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('AdsService: impression failed: $e');
    }
  }

  Future<int> recordClick(String adId) async {
    try {
      final res = await http.post(Uri.parse(ApiConfig.apiPath('/ads/$adId/click'), )).timeout(const Duration(seconds: 5));
      final data = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body) as Map<String, dynamic>;
      if (data['rewarded'] == true) {
        final points = (data['points'] as num?)?.toInt() ?? 0;
        if (points > 0) walletService.addPoints(points, 'Ad interaction reward');
        return points;
      }
    } catch (e) {
      debugPrint('AdsService: click failed: $e');
    }
    return 0;
  }
}

/// Shows ads in shorts after [interval] of continuous watching for free
/// users; subscribers are exempt. Configure with [start]/[stop].
class AdOverlayScheduler {
  final Duration interval;
  final void Function() onFire;
  bool _subscribed = false;
  bool _running = false;

  AdOverlayScheduler({this.interval = const Duration(minutes: 2), required this.onFire});

  bool get subscribed => _subscribed;
  set subscribed(bool value) => _subscribed = value;

  void start() {
    if (_running) return;
    _running = true;
    _schedule();
  }

  Future<void> _schedule() async {
    while (_running) {
      await Future.delayed(interval);
      if (!_running) break;
      if (_subscribed) continue;
      final ads = adsService.banners;
      if (adsService.enabled && ads.isNotEmpty) {
        onFire();
      }
    }
  }

  void stop() => _running = false;
}

final adsService = AdsService();
