// snackbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../provider/translation_service.dart';

enum SnackbarType {
  success(duration: Duration(seconds: 5), backgroundColor: Color(0xFF1B5E20), icon: Icons.check_circle_outline_rounded),
  error(duration: Duration(seconds: 7), backgroundColor: Color(0xFFB71C1C), icon: Icons.error_outline_rounded),
  info(duration: Duration(seconds: 6), backgroundColor: Color(0xFF0D47A1), icon: Icons.info_outline_rounded);

  final Duration duration;
  final Color backgroundColor;
  final IconData icon;

  const SnackbarType({required this.duration, required this.backgroundColor, required this.icon});
}

final snackbarServiceProvider = Provider<SnackbarService>((ref) {
  return SnackbarService(ref);
});

class SnackbarService {
  final Ref ref;

  SnackbarService(this.ref);

  /// Shows a snackbar with automatic translation
  Future<void> showTranslatedSnackBar(String content, {required SnackbarType type, bool wait = false}) async {
    final translatedContent = await _getTranslatedText(content);
    _showSnackBar(translatedContent, type: type, wait: wait);
  }

  /// Shows multiple snackbars with translations
  Future<void> showTranslatedSnackBarBatch(Map<String, SnackbarType> messages, {bool wait = true}) async {
    for (final entry in messages.entries) {
      await showTranslatedSnackBar(entry.key, type: entry.value, wait: wait);
      // Add small delay between consecutive snackbars
      if (messages.length > 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Gets translated text from the translation service
  Future<String> _getTranslatedText(String text) async {
    try {
      final translation = await ref.read(autoTranslationTextProvider(text).future);
      return translation;
    } catch (e) {
      // Fallback to original text if translation fails
      return text;
    }
  }

  /// Internal method to display the actual snackbar
  void _showSnackBar(String content, {required SnackbarType type, bool wait = false}) {
    final scaffoldMessenger = MyApp.scaffoldMessengerKey.currentState;
    if (scaffoldMessenger == null) return;

    if (!wait) scaffoldMessenger.clearSnackBars();
    content = content.toUpperCase();

    final backgroundColor = type.backgroundColor;
    final textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1.1, fontSize: 14);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.only(bottom: bottomMargin, left: 6, right: 6),
      ),
    );
  }

  double _getSnackBarBottomMargin() {
    return 3;
  }
}

// Legacy function for backward compatibility
void showSnackBar(String content, {required SnackbarType type, bool wait = false}) {
  final scaffoldMessenger = MyApp.scaffoldMessengerKey.currentState;
  if (scaffoldMessenger == null) return;

  if (!wait) scaffoldMessenger.clearSnackBars();
  content = content.toUpperCase();

  final backgroundColor = type.backgroundColor;
  final textStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w400, letterSpacing: 1.1, fontSize: 14);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.only(bottom: bottomMargin, left: 6, right: 6),
    ),
  );
}

double _getSnackBarBottomMargin() {
  return 3;
}
