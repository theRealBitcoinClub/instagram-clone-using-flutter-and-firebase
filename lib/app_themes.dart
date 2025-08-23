import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';

class AppThemes {
  static const int LightBlue = 0;
  static const int LightRed = 1;
  static const int Dark = 2;
}
final themeCollection = ThemeCollection(
  themes: {
    AppThemes.LightBlue: ThemeData(primarySwatch: Colors.blue),
    AppThemes.LightRed: ThemeData(primarySwatch: Colors.red),
    AppThemes.Dark: ThemeData.dark(),
  },
  fallbackTheme: ThemeData.light(),
);