import 'package:shared_preferences/shared_preferences.dart';

/// Small wrapper over SharedPreferences for app-level flags.
class AppPrefs {
  static const _onboardingSeenKey = 'onboarding_seen';

  static Future<bool> get onboardingSeen async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
