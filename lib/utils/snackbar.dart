// snackbar.dart
import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

void showSnackBar(String content, BuildContext context, {required SnackbarType type}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  content = content.toUpperCase();
  // Determine colors based on type
  Color backgroundColor;
  TextStyle textStyle;

  switch (type) {
    case SnackbarType.success:
      backgroundColor = Colors.green[900] ?? colorScheme.primaryContainer;
      textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1.1, fontSize: 16);
      break;
    case SnackbarType.error:
      backgroundColor = Colors.red[900] ?? colorScheme.errorContainer;
      textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1.1, fontSize: 16);
      break;
    case SnackbarType.info:
      backgroundColor = Colors.orange[900] ?? colorScheme.secondaryContainer;
      textStyle = TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w400, // Not bold for info
        letterSpacing: 1.1,
        fontSize: 16,
      );
      break;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 3),
        // animation: ,
        // dismissDirection: DismissDirection.down,
        content: Text(content, style: textStyle, textAlign: TextAlign.center),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
        elevation: 6.0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
