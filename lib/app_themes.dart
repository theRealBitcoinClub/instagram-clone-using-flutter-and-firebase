import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Color Palette ---
const Color primaryGreen = Color(0xFF2E7D32); // A solid, accessible green
const Color lightGreenAccent = Color(0xFF81C784); // A lighter, softer green
const Color darkGreenShade = Color(0xFF1B5E20); // A darker shade for depth

const Color primaryDarkGrey = Color(0xFF212121); // For dark backgrounds, dark text
const Color secondaryDarkGrey = Color(0xFF303030); // Slightly lighter dark grey
const Color primaryLightGrey = Color(0xFFE0E0E0); // For light backgrounds, dividers
const Color secondaryLightGrey = Color(0xFFF5F5F5); // Very light grey, almost off-white

const Color textOnDark = Colors.white; // White text on dark backgrounds
const Color textOnLight = Colors.black87; // Dark grey/black text on light backgrounds
const Color subtleTextOnDark = Color(0xFFBDBDBD); // Light grey text on dark
const Color subtleTextOnLight = Color(0xFF757575); // Medium grey text on light

// --- Typography (Elegant Font Sizes - adjust as needed) ---
TextTheme _buildTextTheme(TextTheme base, Color textColor, Color displayColor) {
  return base
      .copyWith(
        // Headlines - Could use a more distinct "elegant" font if you add one via google_fonts
        displayLarge: base.displayLarge?.copyWith(fontSize: 48.0, fontWeight: FontWeight.w300, color: displayColor, letterSpacing: -1.5),
        displayMedium: base.displayMedium?.copyWith(fontSize: 34.0, fontWeight: FontWeight.w400, color: displayColor, letterSpacing: -0.5),
        displaySmall: base.displaySmall?.copyWith(fontSize: 24.0, fontWeight: FontWeight.w400, color: displayColor),

        headlineMedium: base.headlineMedium?.copyWith(fontSize: 20.0, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.15),
        headlineSmall: base.headlineSmall?.copyWith(fontSize: 18.0, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.1),

        titleLarge: base.titleLarge?.copyWith(fontSize: 16.0, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.15),
        titleMedium: base.titleMedium?.copyWith(fontSize: 14.0, fontWeight: FontWeight.w400, color: textColor, letterSpacing: 0.1),
        titleSmall: base.titleSmall?.copyWith(fontSize: 12.0, fontWeight: FontWeight.w500, color: textColor, letterSpacing: 0.05),

        bodyLarge: base.bodyLarge?.copyWith(fontSize: 16.0, fontWeight: FontWeight.w400, color: textColor, letterSpacing: 0.5),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.25,
        ), // Default text
        bodySmall: base.bodySmall?.copyWith(fontSize: 12.0, fontWeight: FontWeight.w400, color: textColor, letterSpacing: 0.4),

        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 1.25,
        ), // For buttons
        labelMedium: base.labelMedium?.copyWith(fontSize: 12.0, fontWeight: FontWeight.w400, color: textColor, letterSpacing: 0.5),
        labelSmall: base.labelSmall?.copyWith(fontSize: 10.0, fontWeight: FontWeight.w400, color: textColor, letterSpacing: 1.5),
      )
      .apply(
        // You can apply a global font family here if you have one
        // fontFamily: 'YourElegantFont',
      );
}

// --- Cupertino Text Theme ---
CupertinoTextThemeData _buildCupertinoTextTheme(Brightness brightness, Color textColor, Color displayColor) {
  // Use the default CupertinoTextThemeData and adjust colors based on brightness
  final base = CupertinoTextThemeData();

  return base.copyWith(
    textStyle: TextStyle(fontSize: 14.0, color: textColor),
    navTitleTextStyle: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: brightness == Brightness.light ? Colors.white : textOnDark,
    ),
    navLargeTitleTextStyle: TextStyle(fontSize: 34.0, fontWeight: FontWeight.w700, color: displayColor),
    tabLabelTextStyle: TextStyle(fontSize: 10.0, color: textColor),
    pickerTextStyle: TextStyle(fontSize: 21.0, color: textColor),
  );
}

// --- Light Theme ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryGreen,
  primaryColorDark: darkGreenShade, // Used by some components for a darker primary variant
  // primaryColorLight: lightGreenAccent, // Can be used for highlights
  scaffoldBackgroundColor: primaryLightGrey, // Very light grey for main background
  canvasColor: secondaryLightGrey, // Background for cards, dialogs, drawers
  cardColor: secondaryLightGrey,
  dividerColor: primaryLightGrey, // Subtle dividers
  hintColor: subtleTextOnLight, // For hint text in TextFields
  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: primaryGreen,
    unselectedItemColor: subtleTextOnLight,
    elevation: 4.0,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),

  // Bottom App Bar Theme
  // bottomAppBarTheme: BottomAppBarThemeData(
  //   color: Colors.white,
  //   elevation: 8.0,
  //   shadowColor: Colors.black.withOpacity(0.2),
  //   surfaceTintColor: primaryGreen.withOpacity(0.08),
  //   height: kBottomNavigationBarHeight + 16,
  //   padding: EdgeInsets.zero,
  // ),
  colorScheme: ColorScheme.light(
    primary: primaryGreen,
    onPrimary: Colors.white, // Text/icons on primary color
    secondary: lightGreenAccent, // Lighter green for accents
    onSecondary: primaryDarkGrey, // Text/icons on secondary color
    surface: secondaryLightGrey, // Cards, sheets, dialogs
    onSurface: textOnLight, // Main text color
    background: secondaryLightGrey, // Overall background
    onBackground: textOnLight,
    error: Colors.redAccent, // Standard error color
    onError: Colors.white,
    surfaceVariant: primaryLightGrey, // For slightly different surfaces
    onSurfaceVariant: textOnLight, // Text on surfaceVariant
    outline: subtleTextOnLight, // Borders
    shadow: Colors.black.withOpacity(0.2), // For BottomAppBar shadow
    surfaceTint: primaryGreen.withOpacity(0.08), // For BottomAppBar surface tint
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white, // Text and icons on AppBar
    elevation: 2.0,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    toolbarTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
    iconTheme: IconThemeData(color: Colors.white),
    actionsIconTheme: IconThemeData(color: Colors.white),
  ),

  textTheme: _buildTextTheme(ThemeData.light().textTheme, textOnLight, primaryDarkGrey),

  // Cupertino Theme for iOS-style widgets
  cupertinoOverrideTheme: CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    primaryContrastingColor: Colors.white,
    barBackgroundColor: primaryGreen,
    scaffoldBackgroundColor: secondaryLightGrey,
    textTheme: _buildCupertinoTextTheme(Brightness.light, textOnLight, primaryDarkGrey),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: primaryGreen, // Green progress bars
    linearTrackColor: primaryLightGrey,
    circularTrackColor: primaryLightGrey,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryGreen, // Hyperlink color
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
        decorationColor: primaryGreen,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryLightGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryGreen, width: 2),
    ),
    hintStyle: TextStyle(color: subtleTextOnLight),
    labelStyle: TextStyle(color: textOnLight),
  ),

  iconTheme: const IconThemeData(
    color: primaryDarkGrey, // Default icon color
  ),
  primaryIconTheme: const IconThemeData(
    color: primaryGreen, // Icons related to primary actions
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textOnLight),
    contentTextStyle: TextStyle(fontSize: 14, color: textOnLight),
    elevation: 6.0,
  ),

  // For hyperlinks not covered by TextButton (e.g., in Text.rich with recognizer)
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: primaryGreen,
    selectionColor: lightGreenAccent.withOpacity(0.5),
    selectionHandleColor: primaryGreen,
  ),

  // Icon button theme for BottomAppBar
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: primaryDarkGrey, // Default icon color for BottomAppBar
      disabledForegroundColor: primaryDarkGrey.withAlpha(111), // Disabled icon color
    ),
  ),
);

// --- Dark Theme ---
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryGreen, // Green still primary
  primaryColorDark: darkGreenShade,
  // primaryColorLight: lightGreenAccent,
  scaffoldBackgroundColor: primaryDarkGrey, // Dark grey for main background
  canvasColor: secondaryDarkGrey, // Background for cards, dialogs
  cardColor: primaryDarkGrey,
  dividerColor: primaryLightGrey.withOpacity(0.3), // More subtle dividers on dark
  hintColor: subtleTextOnDark,

  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: primaryDarkGrey,
    selectedItemColor: lightGreenAccent,
    unselectedItemColor: subtleTextOnDark,
    elevation: 4.0,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    unselectedLabelStyle: const TextStyle(fontSize: 12),
    showSelectedLabels: true,
    showUnselectedLabels: true,
  ),

  // Bottom App Bar Theme
  // bottomAppBarTheme: BottomAppBarThemeData(
  //   color: secondaryDarkGrey,
  //   elevation: 8.0,
  //   shadowColor: Colors.black.withOpacity(0.4),
  //   surfaceTintColor: lightGreenAccent.withOpacity(0.08),
  //   height: kBottomNavigationBarHeight + 16,
  //   padding: EdgeInsets.zero,
  // ),
  colorScheme: ColorScheme.dark(
    primary: primaryGreen,
    onPrimary: Colors.white,
    secondary: lightGreenAccent,
    onSecondary: primaryDarkGrey,
    surface: primaryDarkGrey, // Cards, sheets
    onSurface: textOnDark, // Main text color
    background: primaryDarkGrey, // Overall background
    onBackground: textOnDark,
    error: Colors.red,
    onError: Colors.white,
    surfaceVariant: const Color(0xFF424242), // Slightly different dark surfaces
    onSurfaceVariant: textOnDark,
    outline: primaryLightGrey, // Borders
    shadow: Colors.black.withOpacity(0.4), // For BottomAppBar shadow
    surfaceTint: lightGreenAccent.withOpacity(0.08), // For BottomAppBar surface tint
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: darkGreenShade, // Darker AppBar
    foregroundColor: Colors.white,
    elevation: 2.0,
    titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    toolbarTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    actionsIconTheme: const IconThemeData(color: Colors.white),
  ),

  textTheme: _buildTextTheme(ThemeData.dark().textTheme, textOnDark, lightGreenAccent),

  // Cupertino Theme for iOS-style widgets
  cupertinoOverrideTheme: CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    primaryContrastingColor: Colors.white,
    barBackgroundColor: secondaryDarkGrey,
    scaffoldBackgroundColor: primaryDarkGrey,
    textTheme: _buildCupertinoTextTheme(Brightness.dark, textOnDark, lightGreenAccent),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: primaryGreen, // Green progress bars
    linearTrackColor: primaryDarkGrey, // Darker track
    circularTrackColor: primaryDarkGrey,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: lightGreenAccent, // Lighter green for hyperlinks on dark
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
        decorationColor: lightGreenAccent,
      ),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryLightGrey.withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: lightGreenAccent, width: 2),
    ),
    hintStyle: TextStyle(color: subtleTextOnDark),
    labelStyle: TextStyle(color: textOnDark),
    // fillColor: Colors.white.withOpacity(0.05), // Subtle fill for text fields
    // filled: true,
  ),

  iconTheme: const IconThemeData(
    color: textOnDark, // Default icon color (white)
  ),
  primaryIconTheme: const IconThemeData(
    color: lightGreenAccent, // Icons related to primary actions
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: secondaryDarkGrey,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textOnDark),
    contentTextStyle: TextStyle(fontSize: 14, color: textOnDark),
    elevation: 6.0,
  ),

  textSelectionTheme: TextSelectionThemeData(
    cursorColor: lightGreenAccent,
    selectionColor: primaryGreen.withOpacity(0.5),
    selectionHandleColor: lightGreenAccent,
  ),

  // Icon button theme for BottomAppBar
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: textOnDark, // Default icon color for BottomAppBar
      disabledForegroundColor: textOnDark.withAlpha(111), // Disabled icon color
    ),
  ),
);

// Helper function to get appropriate icon color for BottomAppBar based on theme
Color getBottomAppBarIconColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.light ? primaryDarkGrey : textOnDark;
}
