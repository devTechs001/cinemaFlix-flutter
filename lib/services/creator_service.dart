import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'wallet_service.dart';

class CreatorVideo {
  final String id;
  final String title;
  final String thumbnail;
  final int views;
  final int likes;
  final int comments;
  final DateTime uploadedAt;
  final String duration;
  final String category;
  final bool isPublished;

  const CreatorVideo({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.views,
    required this.likes,
    required this.comments,
    required this.uploadedAt,
    required this.duration,
    required this.category,
    this.isPublished = true,
  });
}

class CreatorStats {
  final int totalViews;
  final int totalSubscribers;
  final int totalVideos;
  final int totalEarnings;
  final int viewsToday;
  final int subscribersToday;
  final double watchTimeHours;

  const CreatorStats({
    required this.totalViews,
    required this.totalSubscribers,
    required this.totalVideos,
    required this.totalEarnings,
    required this.viewsToday,
    required this.subscribersToday,
    required this.watchTimeHours,
  });
}

class CreatorService extends ChangeNotifier {
  bool _isCreator = false;
  bool _onboarded = false;
  int _pendingPayout = 12450;
  bool _ready = false;

  bool get isCreator => _isCreator;
  bool get onboarded => _onboarded;
  int get pendingPayout => _pendingPayout;

  Future<void> initialize() async {
    if (_ready) return;
    _ready = true;
    final prefs = await SharedPreferences.getInstance();
    _isCreator = prefs.getBool('creator_mode') ?? false;
    _onboarded = _isCreator;
    _pendingPayout = prefs.getInt('creator_payout') ?? 12450;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('creator_mode', _isCreator);
    await prefs.setInt('creator_payout', _pendingPayout);
  }

  void enableCreatorMode() {
    _isCreator = true;
    _onboarded = true;
    _persist();
    notifyListeners();
  }

  void disableCreatorMode() {
    _isCreator = false;
    _persist();
    notifyListeners();
  }

  int cashOutToWallet() {
    if (_pendingPayout <= 0) return 0;
    final diamonds = (_pendingPayout ~/ 10).clamp(1, 5000);
    walletService.addDiamonds(diamonds, 'Creator payout');
    _pendingPayout = 0;
    _persist();
    notifyListeners();
    return diamonds;
  }

  void publishVideo(String id) {
    final i = videos.indexWhere((v) => v.id == id);
    if (i < 0) return;
    final v = videos[i];
    videos[i] = CreatorVideo(
      id: v.id,
      title: v.title,
      thumbnail: v.thumbnail,
      views: v.views,
      likes: v.likes,
      comments: v.comments,
      uploadedAt: v.uploadedAt,
      duration: v.duration,
      category: v.category,
      isPublished: true,
    );
    notifyListeners();
  }

  final CreatorStats stats = const CreatorStats(
    totalViews: 45832,
    totalSubscribers: 2891,
    totalVideos: 47,
    totalEarnings: 12450,
    viewsToday: 892,
    subscribersToday: 23,
    watchTimeHours: 3412,
  );

  final List<CreatorVideo> videos = [
    CreatorVideo(id: 'v1', title: 'Dune 2 - Full Movie Review', thumbnail: '🎬', views: 12450, likes: 892, comments: 134, uploadedAt: DateTime(2026, 6, 5), duration: '12:34', category: 'Reviews'),
    CreatorVideo(id: 'v2', title: 'Top 10 Sci-Fi Movies 2026', thumbnail: '🚀', views: 8730, likes: 654, comments: 98, uploadedAt: DateTime(2026, 6, 3), duration: '8:21', category: 'Lists'),
    CreatorVideo(id: 'v3', title: 'Oppenheimer - Deep Analysis', thumbnail: '💣', views: 15200, likes: 1203, comments: 256, uploadedAt: DateTime(2026, 5, 28), duration: '15:47', category: 'Analysis'),
    CreatorVideo(id: 'v4', title: 'Movie News Weekly #42', thumbnail: '📰', views: 5600, likes: 412, comments: 67, uploadedAt: DateTime(2026, 5, 25), duration: '6:55', category: 'News'),
    CreatorVideo(id: 'v5', title: 'How The Batman Changed Cinema', thumbnail: '🦇', views: 3852, likes: 301, comments: 45, uploadedAt: DateTime(2026, 5, 20), duration: '10:12', category: 'Analysis'),
    CreatorVideo(id: 'v6', title: 'Movie Trivia Challenge', thumbnail: '🧠', views: 9800, likes: 723, comments: 189, uploadedAt: DateTime(2026, 5, 15), duration: '5:30', category: 'Fun'),
  ];

  final List<Map<String, dynamic>> recentComments = [
    {'user': 'Sarah J.', 'avatar': '🎬', 'text': 'Amazing review! Totally agree with your take on the cinematography.', 'time': '2h ago', 'likes': 12},
    {'user': 'Mike R.', 'avatar': '🎮', 'text': 'When is part 3 coming out? Need more content like this!', 'time': '5h ago', 'likes': 8},
    {'user': 'Emma W.', 'avatar': '🎨', 'text': 'This analysis changed how I see the film. Great work!', 'time': '1d ago', 'likes': 24},
  ];

  final List<Map<String, dynamic>> dailyViews = [
    {'day': 'Mon', 'views': 1200},
    {'day': 'Tue', 'views': 1800},
    {'day': 'Wed', 'views': 1400},
    {'day': 'Thu', 'views': 2200},
    {'day': 'Fri', 'views': 2800},
    {'day': 'Sat', 'views': 3500},
    {'day': 'Sun', 'views': 2900},
  ];

  void uploadVideo(String title, String category) {
    videos.insert(0, CreatorVideo(
      id: 'v${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      thumbnail: '🎥',
      views: 0,
      likes: 0,
      comments: 0,
      uploadedAt: DateTime.now(),
      duration: '0:00',
      category: category,
      isPublished: false,
    ));
    notifyListeners();
  }

  void deleteVideo(String id) {
    videos.removeWhere((v) => v.id == id);
    notifyListeners();
  }
}

final creatorService = CreatorService();
