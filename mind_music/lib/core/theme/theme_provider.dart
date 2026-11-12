import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeProvider with ChangeNotifier {
  AppThemeMode _currentMode = AppThemeMode.liquidGlass;
  bool _ambientDynamicBlur = true;

  AppThemeMode get currentMode => _currentMode;
  bool get ambientDynamicBlur => _ambientDynamicBlur;
  ThemeData get themeData => AppTheme.getTheme(_currentMode);

  void setTheme(AppThemeMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  void toggleAmbientDynamicBlur() {
    _ambientDynamicBlur = !_ambientDynamicBlur;
    notifyListeners();
  }
}
