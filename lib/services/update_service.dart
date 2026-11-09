import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateAsset {
  final String name;
  final String url;
  final int size;

  UpdateAsset({required this.name, required this.url, this.size = 0});
}

class UpdateInfo {
  final String version;
  final String buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;
  final int fileSize;
  final List<UpdateAsset> assets;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
    this.fileSize = 0,
    this.assets = const [],
  });

  String? get apkUrl {
    for (final a in assets) {
      if (a.name.toLowerCase().endsWith('.apk')) return a.url;
    }
    return null;
  }
}

class UpdateService extends ChangeNotifier {
  static const githubRepo = 'devTechs001/cinemaFlix-flutter';
  static const releasesUrl =
      'https://github.com/devTechs001/cinemaFlix-flutter/releases/latest';
  static const repoUrl = 'https://github.com/devTechs001/cinemaFlix-flutter';
  static const sourceZipUrl =
      'https://github.com/devTechs001/cinemaFlix-flutter/archive/refs/heads/main.zip';

  UpdateInfo? _latestUpdate;
  bool _isChecking = false;
  bool _autoUpdate = true;
  DateTime? _lastChecked;
  double _updateProgress = 0.0;
  Timer? _periodicCheck;
  bool _isDownloading = false;
  bool _downloadComplete = false;
  String? _error;

  UpdateInfo? get latestUpdate => _latestUpdate;
  bool get isChecking => _isChecking;
  bool get autoUpdate => _autoUpdate;
  DateTime? get lastChecked => _lastChecked;
  double get updateProgress => _updateProgress;
  bool get isDownloading => _isDownloading;
  bool get downloadComplete => _downloadComplete;
  String? get error => _error;

  set autoUpdate(bool value) {
    _autoUpdate = value;
    if (value) {
      _startPeriodicCheck();
    } else {
      _stopPeriodicCheck();
    }
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
    _error = null;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final res = await http
          .get(
            Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest'),
            headers: {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'cinemaflix-app',
            },
          )
          .timeout(const Duration(seconds: 8));

      _updateProgress = 0.7;
      notifyListeners();

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final tag = (json['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^v'), '');
        final notes = (json['body'] as String?)?.trim();
        final assets = <UpdateAsset>[];
        for (final raw in (json['assets'] as List? ?? const [])) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          assets.add(UpdateAsset(
            name: m['name'] as String? ?? 'asset',
            url: m['browser_download_url'] as String? ?? '',
            size: (m['size'] as num?)?.toInt() ?? 0,
          ));
        }
        final version = tag.isEmpty ? currentVersion : tag;
        _latestUpdate = UpdateInfo(
          version: version,
          buildNumber: '${json['id'] ?? packageInfo.buildNumber}',
          releaseNotes: (notes == null || notes.isEmpty)
              ? 'Latest CinemaFlix build from GitHub.'
              : notes,
          downloadUrl: json['html_url'] as String? ?? releasesUrl,
          fileSize: assets.fold<int>(0, (s, a) => s + a.size),
          assets: assets,
        );
        _lastChecked = DateTime.now();
        _updateProgress = 1.0;
        notifyListeners();
        return tag.isNotEmpty && _compareVersions(tag, currentVersion) > 0;
      }

      // No published release yet — still expose the repo as the install source.
      _latestUpdate = UpdateInfo(
        version: currentVersion,
        buildNumber: packageInfo.buildNumber,
        releaseNotes:
            'No GitHub release tagged yet. Share the repo or grab source from main.',
        downloadUrl: releasesUrl,
      );
      return false;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      _error = 'Could not reach GitHub';
      _latestUpdate ??= UpdateInfo(
        version: '0.1.0',
        buildNumber: '1',
        releaseNotes: 'Install CinemaFlix from GitHub when you are online.',
        downloadUrl: releasesUrl,
      );
    } finally {
      _isChecking = false;
      _updateProgress = 1.0;
      _lastChecked = DateTime.now();
      notifyListeners();
    }
    return false;
  }

  int _compareVersions(String a, String b) {
    final partsA = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final partsB = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
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
