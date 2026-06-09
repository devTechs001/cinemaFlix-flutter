import 'package:flutter/foundation.dart';

enum DownloadStatus { pending, downloading, completed, paused, failed }

class DownloadItem {
  final String id;
  final String title;
  final String genre;
  final String year;
  final String rating;
  final double fileSizeMB;
  final String quality;
  DownloadStatus status;
  double progress;
  final DateTime addedAt;
  String? filePath;

  DownloadItem({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    this.fileSizeMB = 450,
    this.quality = 'HD',
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    DateTime? addedAt,
    this.filePath,
  }) : addedAt = addedAt ?? DateTime.now();
}

class DownloadService extends ChangeNotifier {
  final List<DownloadItem> _downloads = [];

  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<DownloadItem> get completedDownloads => _downloads.where((d) => d.status == DownloadStatus.completed).toList();
  List<DownloadItem> get activeDownloads => _downloads.where((d) => d.status == DownloadStatus.downloading || d.status == DownloadStatus.pending).toList();

  double get totalDownloadedMB {
    return _downloads.where((d) => d.status == DownloadStatus.completed).fold(0.0, (sum, d) => sum + d.fileSizeMB);
  }

  int get totalDownloads => _downloads.length;

  bool isDownloaded(String movieId) {
    return _downloads.any((d) => d.id == movieId && d.status == DownloadStatus.completed);
  }

  DownloadStatus? getStatus(String movieId) {
    return _downloads.cast<DownloadItem?>().firstWhere(
      (d) => d!.id == movieId,
      orElse: () => null,
    )?.status;
  }

  Future<void> startDownload(String movieId, String title, String genre, String year, String rating, {String quality = 'HD'}) async {
    final existing = _downloads.where((d) => d.id == movieId).toList();
    if (existing.isNotEmpty) {
      if (existing.first.status == DownloadStatus.completed) return;
      existing.first.status = DownloadStatus.downloading;
      existing.first.progress = 0.0;
      notifyListeners();
      await _simulateDownload(existing.first);
      return;
    }

    final item = DownloadItem(
      id: movieId,
      title: title,
      genre: genre,
      year: year,
      rating: rating,
      quality: quality,
      status: DownloadStatus.downloading,
    );
    _downloads.insert(0, item);
    notifyListeners();
    await _simulateDownload(item);
  }

  Future<void> _simulateDownload(DownloadItem item) async {
    item.status = DownloadStatus.downloading;
    item.progress = 0.0;
    notifyListeners();

    final steps = 20;
    for (var i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      item.progress = i / steps;
      notifyListeners();
    }

    item.status = DownloadStatus.completed;
    item.progress = 1.0;
    notifyListeners();
  }

  void pauseDownload(String movieId) {
    final item = _downloads.where((d) => d.id == movieId).toList();
    if (item.isNotEmpty && item.first.status == DownloadStatus.downloading) {
      item.first.status = DownloadStatus.paused;
      notifyListeners();
    }
  }

  void resumeDownload(String movieId) {
    final item = _downloads.where((d) => d.id == movieId).toList();
    if (item.isNotEmpty && item.first.status == DownloadStatus.paused) {
      _simulateDownload(item.first);
    }
  }

  void removeDownload(String movieId) {
    _downloads.removeWhere((d) => d.id == movieId);
    notifyListeners();
  }

  void clearCompleted() {
    _downloads.removeWhere((d) => d.status == DownloadStatus.completed);
    notifyListeners();
  }

  void retryFailed(String movieId) {
    final item = _downloads.where((d) => d.id == movieId).toList();
    if (item.isNotEmpty && item.first.status == DownloadStatus.failed) {
      _simulateDownload(item.first);
    }
  }
}

final downloadService = DownloadService();
