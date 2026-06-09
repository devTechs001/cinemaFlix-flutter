import 'dart:io';
import 'package:flutter/foundation.dart';

enum StorageAlertLevel { ok, warning, critical }

class StorageInfo {
  final int freeBytes;
  final int totalBytes;
  final int usedBytes;

  StorageInfo({required this.freeBytes, required this.totalBytes, required this.usedBytes});

  double get usedPercent => totalBytes > 0 ? usedBytes / totalBytes : 0;
  double get freePercent => totalBytes > 0 ? freeBytes / totalBytes : 0;

  String get freeFormatted => _formatBytes(freeBytes);
  String get usedFormatted => _formatBytes(usedBytes);
  String get totalFormatted => _formatBytes(totalBytes);

  StorageAlertLevel get alertLevel {
    if (freePercent < 0.05) return StorageAlertLevel.critical;
    if (freePercent < 0.15) return StorageAlertLevel.warning;
    return StorageAlertLevel.ok;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class StorageService extends ChangeNotifier {
  StorageInfo? _info;
  bool _alertedWarning = false;
  bool _alertedCritical = false;
  bool get hasLowSpace => _info != null && _info!.alertLevel != StorageAlertLevel.ok;

  StorageInfo? get info => _info;

  Future<StorageInfo> checkStorage() async {
    try {
      final dir = Directory('/');
      final stat = await dir.stat();
      final free = stat.size > 0 ? stat.size : await _estimateFreeSpace();
      final total = await _getTotalSpace();
      final used = total - free;
      _info = StorageInfo(freeBytes: free, totalBytes: total, usedBytes: used);
      notifyListeners();
      return _info!;
    } catch (_) {
      final total = 256 * 1024 * 1024 * 1024;
      final used = 120 * 1024 * 1024 * 1024;
      _info = StorageInfo(freeBytes: total - used, totalBytes: total, usedBytes: used);
      notifyListeners();
      return _info!;
    }
  }

  Future<int> _estimateFreeSpace() async {
    try {
      final tmpFile = File('${Directory.systemTemp.path}/_storage_test_');
      await tmpFile.writeAsString('x' * (1024 * 1024));
      await tmpFile.delete();
      final stat = await Directory.systemTemp.stat();
      return stat.size;
    } catch (_) {
      return 50 * 1024 * 1024 * 1024;
    }
  }

  Future<int> _getTotalSpace() async {
    try {
      final stat = await Directory.systemTemp.stat();
      return stat.size > 0 ? stat.size : 256 * 1024 * 1024 * 1024;
    } catch (_) {
      return 256 * 1024 * 1024 * 1024;
    }
  }

  bool checkAlertNeeded() {
    if (_info == null) return false;
    final level = _info!.alertLevel;
    if (level == StorageAlertLevel.critical && !_alertedCritical) {
      _alertedCritical = true;
      return true;
    }
    if (level == StorageAlertLevel.warning && !_alertedWarning) {
      _alertedWarning = true;
      return true;
    }
    return false;
  }
}

final storageService = StorageService();
