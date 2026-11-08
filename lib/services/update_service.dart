import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;
  final int fileSize;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
    this.fileSize = 0,
  });
}

class UpdateService extends ChangeNotifier {
  UpdateInfo? _latestUpdate;
  bool _isChecking = false;
  bool _autoUpdate = true;
  DateTime? _lastChecked;
  double _updateProgress = 0.0;
  Timer? _periodicCheck;
  bool _isDownloading = false;
  bool _downloadComplete = false;

  UpdateInfo? get latestUpdate => _latestUpdate;
  bool get isChecking => _isChecking;
  bool get autoUpdate => _autoUpdate;
  DateTime? get lastChecked => _lastChecked;
  double get updateProgress => _updateProgress;
  bool get isDownloading => _isDownloading;
  bool get downloadComplete => _downloadComplete;

  set autoUpdate(bool value) {
    _autoUpdate = value;
    if (value) _startPeriodicCheck();
    else _stopPeriodicCheck();
    notifyListeners();
  }

  void startBackgroundCheck() {
    _startPeriodicCheck();
    if (_lastChecked == null) checkForUpdates();
  }

  void _startPeriodicCheck() {
    _periodicCheck?.cancel();
    _periodicCheck = Timer.periodic(const Duration(hours: 6), (_) {
      checkForUpdates();
    });
  }

  void _stopPeriodicCheck() {
    _periodicCheck?.cancel();
    _periodicCheck = null;
  }

  void setUpdateProgress(double value) {
    _updateProgress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> simulateDownload() async {
    if (_latestUpdate == null) return;
    _isDownloading = true;
    _downloadComplete = false;
    _updateProgress = 0.0;
    notifyListeners();

    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      _updateProgress = i / 10;
      notifyListeners();
    }

    _isDownloading = false;
    _downloadComplete = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    _downloadComplete = false;
    notifyListeners();
  }

  Future<bool> checkForUpdates() async {
    _isChecking = true;
    _updateProgress = 0.0;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      for (var i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        _updateProgress = i / 5;
        notifyListeners();
      }

      const latestVersion = '2.0.0';
      if (_compareVersions(latestVersion, currentVersion) > 0) {
        _latestUpdate = UpdateInfo(
          version: latestVersion,
          buildNumber: '5',
          releaseNotes:
              '🎬 New Social Feed with gifting\n📱 TikTok-style Shorts with heart animations\n💬 Chat rooms with emoji reactions\n💎 Wallet & Diamond system\n🔐 Vault with PIN protection\n❤️ Dating with swipeable cards\n📺 Live streaming with gifting\n⚡ Performance improvements\n🐛 Bug fixes',
          downloadUrl:
              'https://github.com/devTechs001/cinemaFlix-flutter/releases/latest',
          isMandatory: false,
          fileSize: 45200000,
        );
        _lastChecked = DateTime.now();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isChecking = false;
      _updateProgress = 1.0;
      _lastChecked = DateTime.now();
      notifyListeners();
    }
    return false;
  }

  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (var i = 0; i < partsA.length && i < partsB.length; i++) {
      if (partsA[i] != partsB[i]) return partsA[i] - partsB[i];
    }
    return partsA.length - partsB.length;
  }

  @override
  void dispose() {
    _periodicCheck?.cancel();
    super.dispose();
  }
}
