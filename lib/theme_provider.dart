import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving theme choice

import 'app_themes.dart'; // Your theme definitions

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = darkTheme; // Default to light theme
  bool _isDarkMode = false;

  static const String _themePrefKey = 'isDarkMode';

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeData get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePrefKey) ?? false; // Default to false (light mode)
    _currentTheme = _isDarkMode ? darkTheme : lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _currentTheme = _isDarkMode ? darkTheme : lightTheme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _isDarkMode);
  }

  // Optional: Allow setting a specific theme
  void setTheme(bool isDark) {
    if (_isDarkMode == isDark) return; // No change needed
    _isDarkMode = isDark;
    _currentTheme = _isDarkMode ? darkTheme : lightTheme;
    notifyListeners();

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_themePrefKey, _isDarkMode);
    });
  }
}
