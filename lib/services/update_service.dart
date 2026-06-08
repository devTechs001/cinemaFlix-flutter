import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'supabase_service.dart';

class UpdateInfo {
  final String version;
  final String buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
  });
}

class UpdateService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  UpdateInfo? _latestUpdate;
  bool _isChecking = false;

  UpdateInfo? get latestUpdate => _latestUpdate;
  bool get isChecking => _isChecking;

  Future<bool> checkForUpdates() async {
    _isChecking = true;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Mocking a check against Supabase
      // In a real app: 
      // final response = await _supabase.table('app_updates').select().order('created_at').limit(1).single();
      // _latestUpdate = UpdateInfo(version: response['version'], ...);
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulating a newer version found
      const latestVersion = '1.1.0';
      if (latestVersion != currentVersion) {
        _latestUpdate = UpdateInfo(
          version: latestVersion,
          buildNumber: '2',
          releaseNotes: '• New Social Feed added\n• TikTok-style Shorts UI\n• Live Gifting system\n• Realistic Chat with AI\n• Bug fixes and performance improvements',
          downloadUrl: 'https://github.com/devTechs001/cinemaFlix-flutter/releases/latest',
          isMandatory: false,
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
    return false;
  }
}
