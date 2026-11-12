import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService with ChangeNotifier {
  static const String _keyOnboarded = 'mind_music_is_onboarded';
  static const String _keyThemeMode = 'mind_music_theme_mode';

  SharedPreferences? _prefs;
  bool _isOnboarded = false;

  bool get isOnboarded => _isOnboarded;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isOnboarded = _prefs?.getBool(_keyOnboarded) ?? false;
    notifyListeners();
  }

  Future<void> setOnboarded(bool value) async {
    _isOnboarded = value;
    await _prefs?.setBool(_keyOnboarded, value);
    notifyListeners();
  }

  Future<void> saveThemeMode(String themeName) async {
    await _prefs?.setString(_keyThemeMode, themeName);
  }

  String? getSavedThemeMode() {
    return _prefs?.getString(_keyThemeMode);
  }
}
