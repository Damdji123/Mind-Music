import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticLevel {
  soft,
  medium,
  strong,
}

class PreferencesService with ChangeNotifier {
  static const String _keyOnboarded = 'mind_music_is_onboarded';
  static const String _keyThemeMode = 'mind_music_theme_mode';
  static const String _keyAmbientDynamicBlur = 'mind_music_ambient_dynamic_blur';
  static const String _keyPureBlackAmoled = 'mind_music_pure_black_amoled';
  static const String _keyStartupChime = 'mind_music_startup_chime';
  static const String _keyUiSoundVolume = 'mind_music_ui_sound_volume';
  static const String _keyHapticFeedback = 'mind_music_haptic_feedback';
  static const String _keyHapticIntensity = 'mind_music_haptic_intensity';
  static const String _keyGaplessPlayback = 'mind_music_gapless_playback';
  static const String _keyVoiceWakeWord = 'mind_music_voice_wake_word';
  static const String _keyAutoTagMetadata = 'mind_music_auto_tag_metadata';
  static const String _keyAudioOutputQuality = 'mind_music_audio_output_quality';
  static const String _keyAudioExtractorPreset = 'mind_music_audio_extractor_preset';
  static const String _keyLanguage = 'mind_music_language';
  static const String _keyNotifications = 'mind_music_notifications_enabled';

  SharedPreferences? _prefs;

  bool _isOnboarded = false;
  String _themeMode = 'liquidGlass';
  bool _ambientDynamicBlur = true;
  bool _pureBlackAmoled = false;
  bool _startupChime = true;
  double _uiSoundVolume = 0.75;
  bool _hapticFeedback = true;
  HapticLevel _hapticIntensity = HapticLevel.medium;
  bool _gaplessPlayback = true;
  bool _voiceWakeWord = false;
  bool _autoTagMetadata = true;
  String _audioOutputQuality = 'Lossless FLAC & 32bit Hi-Res';
  String _audioExtractorPreset = 'FLAC Lossless';
  String _language = 'Français / English';
  bool _notificationsEnabled = true;

  // Getters
  bool get isOnboarded => _isOnboarded;
  String get themeMode => _themeMode;
  bool get ambientDynamicBlur => _ambientDynamicBlur;
  bool get pureBlackAmoled => _pureBlackAmoled;
  bool get startupChime => _startupChime;
  double get uiSoundVolume => _uiSoundVolume;
  bool get hapticFeedback => _hapticFeedback;
  HapticLevel get hapticIntensity => _hapticIntensity;
  bool get gaplessPlayback => _gaplessPlayback;
  bool get voiceWakeWord => _voiceWakeWord;
  bool get autoTagMetadata => _autoTagMetadata;
  String get audioOutputQuality => _audioOutputQuality;
  String get audioExtractorPreset => _audioExtractorPreset;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isOnboarded = _prefs?.getBool(_keyOnboarded) ?? false;
    _themeMode = _prefs?.getString(_keyThemeMode) ?? 'liquidGlass';
    _ambientDynamicBlur = _prefs?.getBool(_keyAmbientDynamicBlur) ?? true;
    _pureBlackAmoled = _prefs?.getBool(_keyPureBlackAmoled) ?? false;
    _startupChime = _prefs?.getBool(_keyStartupChime) ?? true;
    _uiSoundVolume = _prefs?.getDouble(_keyUiSoundVolume) ?? 0.75;
    _hapticFeedback = _prefs?.getBool(_keyHapticFeedback) ?? true;
    final hapticStr = _prefs?.getString(_keyHapticIntensity) ?? 'medium';
    _hapticIntensity = HapticLevel.values.firstWhere(
      (e) => e.name == hapticStr,
      orElse: () => HapticLevel.medium,
    );
    _gaplessPlayback = _prefs?.getBool(_keyGaplessPlayback) ?? true;
    _voiceWakeWord = _prefs?.getBool(_keyVoiceWakeWord) ?? false;
    _autoTagMetadata = _prefs?.getBool(_keyAutoTagMetadata) ?? true;
    _audioOutputQuality = _prefs?.getString(_keyAudioOutputQuality) ?? 'Lossless FLAC & 32bit Hi-Res';
    _audioExtractorPreset = _prefs?.getString(_keyAudioExtractorPreset) ?? 'FLAC Lossless';
    _language = _prefs?.getString(_keyLanguage) ?? 'Français / English';
    _notificationsEnabled = _prefs?.getBool(_keyNotifications) ?? true;
    notifyListeners();
  }

  Future<void> setOnboarded(bool value) async {
    _isOnboarded = value;
    await _prefs?.setBool(_keyOnboarded, value);
    notifyListeners();
  }

  Future<void> setThemeMode(String mode) async {
    _themeMode = mode;
    await _prefs?.setString(_keyThemeMode, mode);
    notifyListeners();
  }

  Future<void> setAmbientDynamicBlur(bool value) async {
    _ambientDynamicBlur = value;
    await _prefs?.setBool(_keyAmbientDynamicBlur, value);
    notifyListeners();
  }

  Future<void> setPureBlackAmoled(bool value) async {
    _pureBlackAmoled = value;
    if (value) {
      _themeMode = 'oledDark';
      await _prefs?.setString(_keyThemeMode, 'oledDark');
    }
    await _prefs?.setBool(_keyPureBlackAmoled, value);
    notifyListeners();
  }

  Future<void> setStartupChime(bool value) async {
    _startupChime = value;
    await _prefs?.setBool(_keyStartupChime, value);
    notifyListeners();
  }

  Future<void> setUiSoundVolume(double value) async {
    _uiSoundVolume = value.clamp(0.0, 1.0);
    await _prefs?.setDouble(_keyUiSoundVolume, _uiSoundVolume);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    await _prefs?.setBool(_keyHapticFeedback, value);
    notifyListeners();
  }

  Future<void> setHapticIntensity(HapticLevel level) async {
    _hapticIntensity = level;
    await _prefs?.setString(_keyHapticIntensity, level.name);
    triggerHaptic();
    notifyListeners();
  }

  void triggerHaptic() {
    if (!_hapticFeedback) return;
    switch (_hapticIntensity) {
      case HapticLevel.soft:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticLevel.strong:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  Future<void> setGaplessPlayback(bool value) async {
    _gaplessPlayback = value;
    await _prefs?.setBool(_keyGaplessPlayback, value);
    notifyListeners();
  }

  Future<void> setVoiceWakeWord(bool value) async {
    _voiceWakeWord = value;
    await _prefs?.setBool(_keyVoiceWakeWord, value);
    notifyListeners();
  }

  Future<void> setAutoTagMetadata(bool value) async {
    _autoTagMetadata = value;
    await _prefs?.setBool(_keyAutoTagMetadata, value);
    notifyListeners();
  }

  Future<void> setAudioOutputQuality(String quality) async {
    _audioOutputQuality = quality;
    await _prefs?.setString(_keyAudioOutputQuality, quality);
    notifyListeners();
  }

  Future<void> setAudioExtractorPreset(String preset) async {
    _audioExtractorPreset = preset;
    await _prefs?.setString(_keyAudioExtractorPreset, preset);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs?.setString(_keyLanguage, lang);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool(_keyNotifications, value);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _themeMode = 'liquidGlass';
    _ambientDynamicBlur = true;
    _pureBlackAmoled = false;
    _startupChime = true;
    _uiSoundVolume = 0.75;
    _hapticFeedback = true;
    _hapticIntensity = HapticLevel.medium;
    _gaplessPlayback = true;
    _voiceWakeWord = false;
    _autoTagMetadata = true;
    _audioOutputQuality = 'Lossless FLAC & 32bit Hi-Res';
    _audioExtractorPreset = 'FLAC Lossless';
    _language = 'Français / English';
    _notificationsEnabled = true;

    await _prefs?.setString(_keyThemeMode, _themeMode);
    await _prefs?.setBool(_keyAmbientDynamicBlur, _ambientDynamicBlur);
    await _prefs?.setBool(_keyPureBlackAmoled, _pureBlackAmoled);
    await _prefs?.setBool(_keyStartupChime, _startupChime);
    await _prefs?.setDouble(_keyUiSoundVolume, _uiSoundVolume);
    await _prefs?.setBool(_keyHapticFeedback, _hapticFeedback);
    await _prefs?.setString(_keyHapticIntensity, _hapticIntensity.name);
    await _prefs?.setBool(_keyGaplessPlayback, _gaplessPlayback);
    await _prefs?.setBool(_keyVoiceWakeWord, _voiceWakeWord);
    await _prefs?.setBool(_keyAutoTagMetadata, _autoTagMetadata);
    await _prefs?.setString(_keyAudioOutputQuality, _audioOutputQuality);
    await _prefs?.setString(_keyAudioExtractorPreset, _audioExtractorPreset);
    await _prefs?.setString(_keyLanguage, _language);
    await _prefs?.setBool(_keyNotifications, _notificationsEnabled);

    notifyListeners();
  }
}
