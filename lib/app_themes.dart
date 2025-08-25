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
        displayLarge: base.displayLarge?.copyWith(
          fontSize: 48.0,
          fontWeight: FontWeight.w300,
          color: displayColor,
          letterSpacing: -1.5,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontSize: 34.0,
          fontWeight: FontWeight.w400,
          color: displayColor,
          letterSpacing: -0.5,
        ),
        displaySmall: base.displaySmall?.copyWith(fontSize: 24.0, fontWeight: FontWeight.w400, color: displayColor),

        headlineMedium: base.headlineMedium?.copyWith(
          fontSize: 20.0,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.15,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.1,
        ),

        titleLarge: base.titleLarge?.copyWith(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.15,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.1,
        ),
        titleSmall: base.titleSmall?.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.05,
        ),

        bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 16.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.5,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.25,
        ), // Default text
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.4,
        ),

        labelLarge: base.labelLarge?.copyWith(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 1.25,
        ), // For buttons
        labelMedium: base.labelMedium?.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 0.5,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontSize: 10.0,
          fontWeight: FontWeight.w400,
          color: textColor,
          letterSpacing: 1.5,
        ),
      )
      .apply(
        // You can apply a global font family here if you have one
        // fontFamily: 'YourElegantFont',
      );
}

// --- Light Theme ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryGreen,
  primaryColorDark: darkGreenShade, // Used by some components for a darker primary variant
  // primaryColorLight: lightGreenAccent, // Can be used for highlights
  scaffoldBackgroundColor: secondaryLightGrey, // Very light grey for main background
  canvasColor: Colors.white, // Background for cards, dialogs, drawers
  cardColor: Colors.white,
  dividerColor: primaryLightGrey, // Subtle dividers
  hintColor: subtleTextOnLight, // For hint text in TextFields

  colorScheme: const ColorScheme.light(
    primary: primaryGreen,
    onPrimary: Colors.white, // Text/icons on primary color
    secondary: lightGreenAccent, // Lighter green for accents
    onSecondary: primaryDarkGrey, // Text/icons on secondary color
    surface: Colors.white, // Cards, sheets, dialogs
    onSurface: textOnLight, // Main text color
    background: secondaryLightGrey, // Overall background
    onBackground: textOnLight,
    error: Colors.redAccent, // Standard error color
    onError: Colors.white,
    surfaceVariant: primaryLightGrey, // For slightly different surfaces
    onSurfaceVariant: textOnLight, // Text on surfaceVariant
    outline: primaryLightGrey, // Borders
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: primaryGreen,
    foregroundColor: Colors.white, // Text and icons on AppBar
    elevation: 2.0,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
  ),

  textTheme: _buildTextTheme(ThemeData.light().textTheme, textOnLight, primaryDarkGrey),

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
  ),

  // For hyperlinks not covered by TextButton (e.g., in Text.rich with recognizer)
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: primaryGreen,
    selectionColor: lightGreenAccent.withOpacity(0.5),
    selectionHandleColor: primaryGreen,
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
  cardColor: secondaryDarkGrey,
  dividerColor: primaryLightGrey.withOpacity(0.3), // More subtle dividers on dark
  hintColor: subtleTextOnDark,

  colorScheme: const ColorScheme.dark(
    primary: primaryGreen,
    onPrimary: Colors.white,
    secondary: lightGreenAccent,
    onSecondary: primaryDarkGrey,
    surface: secondaryDarkGrey, // Cards, sheets
    onSurface: textOnDark, // Main text color
    background: primaryDarkGrey, // Overall background
    onBackground: textOnDark,
    error: Colors.red,
    onError: Colors.white,
    surfaceVariant: Color(0xFF424242), // Slightly different dark surfaces
    onSurfaceVariant: textOnDark,
    outline: primaryLightGrey, // Borders
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: secondaryDarkGrey, // Darker AppBar
    foregroundColor: Colors.white,
    elevation: 2.0,
    titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
  ),

  textTheme: _buildTextTheme(ThemeData.dark().textTheme, textOnDark, lightGreenAccent),

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
  ),

  textSelectionTheme: TextSelectionThemeData(
    cursorColor: lightGreenAccent,
    selectionColor: primaryGreen.withOpacity(0.5),
    selectionHandleColor: lightGreenAccent,
  ),
);
