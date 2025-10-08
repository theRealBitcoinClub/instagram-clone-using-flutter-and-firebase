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
  // Get the root context from navigator
  // final navigator = Navigator.of(MyApp.scaffoldMessengerKey.currentContext!);
  // final context = navigator.context;

  // if (!wait) ScaffoldMessenger.of(context).clearSnackBars();
  content = content.toUpperCase();

  final backgroundColor = type.backgroundColor;
  final textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1.1, fontSize: 14);
  scaffoldMessenger.showSnackBar(
    // scaffoldMessenger: scaffoldMessenger,
    // ScaffoldMessenger.of(context).showSnackBar(
    // snackBarAnimationStyle: AnimationStyle(duration: Duration(milliseconds: 500), curve: ElasticInOutCurve()),
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
      behavior: SnackBarBehavior.floating, // Changed to floating
      elevation: 6.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)), // All corners rounded for floating
      ),
      margin: EdgeInsets.zero, // This works with floating behavior
      // width: MediaQuery.of(context).size.width, // Set width to screen width
    ),
  );
}
