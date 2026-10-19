import 'package:flutter/material.dart';

/// Holds the current [ThemeMode]. Jarvis looks best dark, so that is
/// the default; the user can change it in Settings.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void toggleDark(bool value) {
    setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }
}
