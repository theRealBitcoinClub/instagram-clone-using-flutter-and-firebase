// In your snackbar.dart
import 'package:flutter/material.dart';

void showSnackBar(String content, BuildContext context) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content, style: TextStyle(color: theme.snackBarTheme.contentTextStyle?.color ?? theme.colorScheme.onInverseSurface)),
      backgroundColor: theme.snackBarTheme.backgroundColor ?? theme.colorScheme.inverseSurface,
      behavior: theme.snackBarTheme.behavior ?? SnackBarBehavior.fixed, // Use themed behavior
      elevation: theme.snackBarTheme.elevation ?? 6.0,
    ),
  );
}
