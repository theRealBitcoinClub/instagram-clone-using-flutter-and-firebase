// snackbar.dart
import 'package:flutter/material.dart';

import '../main.dart';

enum SnackbarType {
  success(duration: Duration(seconds: 5), backgroundColor: Color(0xFF1B5E20), icon: Icons.check_circle_outline_rounded),
  error(duration: Duration(seconds: 7), backgroundColor: Color(0xFFB71C1C), icon: Icons.error_outline_rounded),
  info(duration: Duration(seconds: 6), backgroundColor: Color(0xFF0D47A1), icon: Icons.info_outline_rounded);

  final Duration duration;
  final Color backgroundColor;
  final IconData icon;

  const SnackbarType({required this.duration, required this.backgroundColor, required this.icon});
}

void showSnackBar(String content, {required SnackbarType type, wait = false}) {
  final scaffoldMessenger = MyApp.scaffoldMessengerKey.currentState;
  if (scaffoldMessenger == null) return;

  if (!wait) scaffoldMessenger.clearSnackBars();
  content = content.toUpperCase();

  final backgroundColor = type.backgroundColor;
  final textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1.1, fontSize: 14);

  // Get the bottom margin to avoid navigation bar overlap
  final bottomMargin = _getSnackBarBottomMargin();

  scaffoldMessenger.showSnackBar(
    SnackBar(
      duration: type.duration,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type.icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(content, style: textStyle, textAlign: TextAlign.center),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      elevation: 6.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // All corners rounded for floating
      ),
      margin: EdgeInsets.only(bottom: bottomMargin, left: 6, right: 6),
    ),
  );
}

double _getSnackBarBottomMargin() {
  final context = MyApp.scaffoldMessengerKey.currentContext;
  if (context == null) return 100; // Fallback margin

  final mediaQuery = MediaQuery.of(context);
  final bottomPadding = mediaQuery.padding.bottom;
  final bottomViewInsets = mediaQuery.viewInsets.bottom;

  // Calculate safe bottom margin
  const double navBarHeight = 0; // Your bottom navigation bar height
  const double extraSpacing = 40; // Extra space between snackbar and nav bar

  // For devices with soft navigation bars, we need more margin
  final bool hasSoftNavigationBar = bottomPadding < 20 && bottomViewInsets > 0;

  if (hasSoftNavigationBar) {
    return bottomPadding + navBarHeight + extraSpacing;
  } else {
    return navBarHeight + extraSpacing;
  }
}

// Alternative simplified version - always use consistent margin:
/*
double _getSnackBarBottomMargin() {
  final context = MyApp.scaffoldMessengerKey.currentContext;
  if (context == null) return 80;

  final bottomPadding = MediaQuery.of(context).padding.bottom;
  const navBarHeight = 60;
  const extraSpacing = 10;

  // Always position above navigation bar with consistent spacing
  return bottomPadding + navBarHeight + extraSpacing;
}
*/
