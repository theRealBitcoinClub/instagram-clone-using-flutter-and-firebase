// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_themes.dart';
import 'main.dart'; // Your theme definitions

// State class for theme (optional but good for clarity if more state is added)
class ThemeState {
  final ThemeData currentTheme;
  final bool isDarkMode;

  ThemeState({required this.currentTheme, required this.isDarkMode});
}

final ThemeState defaultThemeState = ThemeState(currentTheme: darkTheme, isDarkMode: true);

class ThemeNotifier extends StateNotifier<AsyncValue<ThemeState>> {
  ThemeNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadThemePreference();
  }

  Ref ref;
  static const String _themePrefKey = 'isDarkMode';

  Future<void> _loadThemePreference() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final isDarkModePref = prefs.getBool(_themePrefKey) ?? true; // Default to false (light mode)
      state = AsyncValue.data(ThemeState(currentTheme: isDarkModePref ? darkTheme : lightTheme, isDarkMode: isDarkModePref));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      // Fallback to a default theme on error
      state = AsyncValue.data(ThemeState(currentTheme: darkTheme, isDarkMode: true));
      print("Error loading theme preference: $e");
    }
  }

  Future<void> toggleTheme() async {
    // Only proceed if current state is data (not loading or error)
    state.whenData((currentThemeState) async {
      final newIsDarkMode = !currentThemeState.isDarkMode;
      state = AsyncValue.data(ThemeState(currentTheme: newIsDarkMode ? darkTheme : lightTheme, isDarkMode: newIsDarkMode));

      try {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool(_themePrefKey, newIsDarkMode);
      } catch (e) {
        print("Error saving theme preference: $e");
        // Optionally revert state or handle error
      }
    });
  }

  Future<void> setTheme(bool isDark) async {
    state.whenData((currentThemeState) async {
      if (currentThemeState.isDarkMode == isDark) return; // No change needed

      state = AsyncValue.data(ThemeState(currentTheme: isDark ? darkTheme : lightTheme, isDarkMode: isDark));

      try {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool(_themePrefKey, isDark);
      } catch (e) {
        print("Error saving theme preference: $e");
      }
    });
  }

  // Getter for convenience, usable only when data is loaded
  bool get isDarkMode {
    return state.maybeWhen(
      data: (themeState) => themeState.isDarkMode,
      orElse: () => false, // Default or handle loading/error appropriately
    );
  }
}

// The global provider for ThemeNotifier
// It will now provide AsyncValue<ThemeState>
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, AsyncValue<ThemeState>>((ref) {
  return ThemeNotifier(ref);
});
// Helper providers to reduce boilerplate
final themeStateProvider = Provider<ThemeState>((ref) {
  return ref.watch(themeNotifierProvider).maybeWhen(data: (state) => state, orElse: () => defaultThemeState);
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeStateProvider).isDarkMode;
});
