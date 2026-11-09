import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateAsset {
  final String name;
  final String url;
  final int size;

  UpdateAsset({required this.name, required this.url, this.size = 0});

  bool get isApk => name.toLowerCase().endsWith('.apk');
  bool get isIpa => name.toLowerCase().endsWith('.ipa');
  bool get isExe =>
      name.toLowerCase().endsWith('.exe') || name.toLowerCase().endsWith('.msix');
  bool get isLinux =>
      name.toLowerCase().endsWith('.appimage') ||
      name.toLowerCase().endsWith('.deb') ||
      name.toLowerCase().contains('linux');
  bool get isMac =>
      name.toLowerCase().endsWith('.dmg') || name.toLowerCase().contains('macos');
  bool get isZip => name.toLowerCase().endsWith('.zip');
}

class UpdateInfo {
  final String version;
  final String buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;
  final int fileSize;
  final List<UpdateAsset> assets;
  final bool isNewer;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
    this.fileSize = 0,
    this.assets = const [],
    this.isNewer = false,
  });

  String? get apkUrl {
    for (final a in assets) {
      if (a.isApk) return a.url;
    }
    return null;
  }

  UpdateAsset? _find(bool Function(UpdateAsset) test) {
    for (final a in assets) {
      if (test(a)) return a;
    }
    return null;
  }

  UpdateAsset? assetForPlatform() {
    if (assets.isEmpty) return null;
    if (kIsWeb) return assets.first;
    try {
      if (Platform.isAndroid) return _find((a) => a.isApk);
      if (Platform.isIOS) return _find((a) => a.isIpa);
      if (Platform.isWindows) {
        return _find((a) => a.isExe || a.name.toLowerCase().contains('windows'));
      }
      if (Platform.isMacOS) return _find((a) => a.isMac);
      if (Platform.isLinux) return _find((a) => a.isLinux);
    } catch (_) {}
    return assets.first;
  }
}

class UpdateService extends ChangeNotifier {
  static const githubRepo = 'devTechs001/cinemaFlix-flutter';
  static const releasesUrl =
      'https://github.com/devTechs001/cinemaFlix-flutter/releases/latest';
  static const repoUrl = 'https://github.com/devTechs001/cinemaFlix-flutter';
  static const sourceZipUrl =
      'https://github.com/devTechs001/cinemaFlix-flutter/archive/refs/heads/main.zip';
  static const _channel = MethodChannel('cinemaflix/installer');

  static final sourceZipAsset = UpdateAsset(
    name: 'cinemaflix-main.zip',
    url: sourceZipUrl,
  );

  UpdateInfo? _latestUpdate;
  bool _isChecking = false;
  bool _autoUpdate = true;
  DateTime? _lastChecked;
  double _updateProgress = 0.0;
  Timer? _periodicCheck;
  bool _isDownloading = false;
  bool _downloadComplete = false;
  String? _error;
  String? _localPath;
  String? _currentVersion;

  UpdateInfo? get latestUpdate => _latestUpdate;
  bool get isChecking => _isChecking;
  bool get autoUpdate => _autoUpdate;
  DateTime? get lastChecked => _lastChecked;
  double get updateProgress => _updateProgress;
  bool get isDownloading => _isDownloading;
  bool get downloadComplete => _downloadComplete;
  String? get error => _error;
  String? get localPath => _localPath;
  String? get currentVersion => _currentVersion;
  bool get hasNewerBuild => _latestUpdate?.isNewer == true;

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
    _periodicCheck = Timer.periodic(const Duration(minutes: 30), (_) {
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

  UpdateAsset fallbackAsset({String? label}) {
    final fromRelease = _latestUpdate?.assetForPlatform();
    if (fromRelease != null) return fromRelease;
    if (label == 'Android' && _latestUpdate?.apkUrl != null) {
      return UpdateAsset(name: 'cinemaflix.apk', url: _latestUpdate!.apkUrl!);
    }
    if (label == 'Source') return sourceZipAsset;
    if (!kIsWeb && Platform.isLinux) {
      final assets = _latestUpdate?.assets ?? const <UpdateAsset>[];
      for (final a in assets) {
        if (a.name.toLowerCase().contains('linux') || a.name.endsWith('.sh')) {
          return a;
        }
      }
    }
    return _latestUpdate?.assets.isNotEmpty == true
        ? _latestUpdate!.assets.first
        : sourceZipAsset;
  }

  Future<String?> downloadAsset(UpdateAsset asset) async {
    if (kIsWeb) {
      _error = 'Download is not available on web';
      notifyListeners();
      return null;
    }
    _isDownloading = true;
    _downloadComplete = false;
    _updateProgress = 0.0;
    _error = null;
    _localPath = null;
    notifyListeners();

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(asset.url));
      req.headers['User-Agent'] = 'cinemaflix-app';
      req.headers['Accept'] = 'application/octet-stream';
      final res = await client.send(req).timeout(const Duration(minutes: 5));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException('Download failed (${res.statusCode})');
      }
      final total = res.contentLength ?? (asset.size > 0 ? asset.size : 0);
      final dir = Directory.systemTemp;
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final safeName = asset.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final file = File('${dir.path}/$safeName');
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          _updateProgress = (received / total).clamp(0.0, 1.0);
          notifyListeners();
        }
      }
      await sink.flush();
      await sink.close();
      _localPath = file.path;
      _updateProgress = 1.0;
      _downloadComplete = true;
      return file.path;
    } catch (e) {
      debugPrint('downloadAsset: $e');
      _error = 'Download failed';
      return null;
    } finally {
      client.close();
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<bool> installLocalFile(String path) async {
    if (kIsWeb) return false;
    try {
      final lower = path.toLowerCase();
      if (Platform.isAndroid && lower.endsWith('.apk')) {
        await _channel.invokeMethod('installApk', {'path': path});
        return true;
      }
      if (Platform.isLinux) {
        if (lower.endsWith('.sh')) {
          await Process.run('chmod', ['+x', path]);
          await Process.start(path, const [], mode: ProcessStartMode.detached);
          return true;
        }
        await Process.run('xdg-open', [path]);
        return true;
      }
      if (Platform.isMacOS) {
        if (lower.endsWith('.sh')) {
          await Process.run('chmod', ['+x', path]);
          await Process.start(path, const [], mode: ProcessStartMode.detached);
          return true;
        }
        await Process.run('open', [path]);
        return true;
      }
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', path]);
        return true;
      }
    } catch (e) {
      debugPrint('installLocalFile: $e');
      _error = 'Could not open installer';
      notifyListeners();
    }
    return false;
  }

  Future<bool> downloadAndInstall({UpdateAsset? asset}) async {
    final chosen = asset ?? fallbackAsset();
    final path = await downloadAsset(chosen);
    if (path == null) return false;
    return installLocalFile(path);
  }

  Future<bool> checkForUpdates() async {
    _isChecking = true;
    _updateProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
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
        final tag =
            (json['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^v'), '');
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
        if (assets.every((a) => !a.isZip)) assets.add(sourceZipAsset);
        final version = tag.isEmpty ? currentVersion : tag;
        final newer = tag.isNotEmpty && _compareVersions(tag, currentVersion) > 0;
        _latestUpdate = UpdateInfo(
          version: version,
          buildNumber: '${json['id'] ?? packageInfo.buildNumber}',
          releaseNotes: (notes == null || notes.isEmpty)
              ? 'Latest CinemaFlix build from GitHub.'
              : notes,
          downloadUrl: json['html_url'] as String? ?? releasesUrl,
          fileSize: assets.fold<int>(0, (s, a) => s + a.size),
          assets: assets,
          isNewer: newer,
        );
        _lastChecked = DateTime.now();
        _updateProgress = 1.0;
        notifyListeners();
        return newer;
      }

      _latestUpdate = UpdateInfo(
        version: currentVersion,
        buildNumber: packageInfo.buildNumber,
        releaseNotes:
            'No GitHub release tagged yet. Download source from main or share the repo.',
        downloadUrl: releasesUrl,
        assets: [sourceZipAsset],
        isNewer: false,
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
        assets: [sourceZipAsset],
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
