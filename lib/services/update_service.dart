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

  /// Checks the `app_updates` table for the newest release and compares
  /// it properly (semver-style) against the installed version.
  /// Returns false when up to date, when the table is empty/missing,
  /// or on any error — never invents an update.
  ///
  /// Expected table columns: version (text), build_number (text/int),
  /// release_notes (text), download_url (text), is_mandatory (bool),
  /// created_at (timestamptz).
  Future<bool> checkForUpdates() async {
    _isChecking = true;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final rows = await _supabase
          .table('app_updates')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return false;

      final latest = rows.first;
      final latestVersion = latest['version'] as String?;
      if (latestVersion == null ||
          !isNewerVersion(latestVersion, packageInfo.version)) {
        return false;
      }

      _latestUpdate = UpdateInfo(
        version: latestVersion,
        buildNumber: latest['build_number']?.toString() ?? '',
        releaseNotes: latest['release_notes'] as String? ?? '',
        downloadUrl: latest['download_url'] as String? ?? '',
        isMandatory: latest['is_mandatory'] as bool? ?? false,
      );
      return true;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// True when [latest] is strictly newer than [current]
  /// (dot-separated numeric versions, e.g. 1.10.0 > 1.9.9).
  static bool isNewerVersion(String latest, String current) {
    List<int> parse(String v) =>
        v.split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final a = parse(latest);
    final b = parse(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av > bv;
    }
    return false;
  }
}
