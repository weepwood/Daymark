import 'package:shared_preferences/shared_preferences.dart';

/// Theme preference, isolated from task persistence.
class AppSettings {
  AppSettings(this._preferences);

  static const darkModeKey = 'daymark.dark_mode';

  final SharedPreferencesAsync _preferences;

  Future<bool> readDarkMode() async {
    try {
      return await _preferences.getBool(darkModeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> writeDarkMode(bool value) async {
    try {
      await _preferences.setBool(darkModeKey, value);
    } catch (_) {
      // The app stays usable with an in-memory preference.
    }
  }
}
