import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart';

class PermissionHelper {
  static void requestNotificationPermission(BuildContext context) async {
    try {
      // For Android 13+ (API 33+), we need to use the permission handler
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isGranted) {
          _initializeOneSignal();
          return;
        }
        // Show custom explanation dialog
        final shouldRequest = await _showPermissionDialog(context);
        if (shouldRequest) {
          final result = await Permission.notification.request();
          if (result == PermissionStatus.granted) {
            _initializeOneSignal();
            _print('Notification permission granted');
          } else {
            _print('Notification permission not granted');
          }
        } else {
          _print('Notification permission later');
        }
      }
    } catch (e) {
      _print('Permission request error: $e');
    }
  }

  static void _initializeOneSignal() {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.error);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      OneSignal.consentRequired(false);
      OneSignal.initialize(dotenv.env['ONE_SIGNAL']!);

      // Set up notification handlers
      setupNotificationHandlers();

      // Clear any existing notifications
      OneSignal.Notifications.clearAll();

      _print('OneSignal initialized successfully');
    } catch (e) {
      Sentry.captureException(e);
      _print('OneSignal initialization failed: $e');
    }
  }

  static const String title = 'Notifications';
  static const String content =
      'A few times per year, Mahakka would like to receive notifications, to keep you updated on important news & free token lotteries.';
  static const String notNow = 'Later';
  static const String allow = 'Allow';

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    try {
      final translations = await _loadDialogTranslations(context);

      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text(translations['title'] ?? title),
              content: Text(translations['content'] ?? content),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(translations['notNow'] ?? notNow)),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(translations['allow'] ?? allow)),
              ],
            ),
          ) ??
          false;
    } catch (e) {
      Sentry.captureException(e);
      return true;
    }
  }

  static Future<Map<String, String>> _loadDialogTranslations(BuildContext context) async {
    try {
      final ref = ProviderScope.containerOf(context, listen: false);

      final titleFuture = ref.read(autoTranslationTextProvider(title).future);
      final contentFuture = ref.read(autoTranslationTextProvider(content).future);
      final notNowFuture = ref.read(autoTranslationTextProvider(notNow).future);
      final allowFuture = ref.read(autoTranslationTextProvider(allow).future);

      final results = await Future.wait([titleFuture, contentFuture, notNowFuture, allowFuture]);

      return {'title': results[0], 'content': results[1], 'notNow': results[2], 'allow': results[3]};
    } catch (e) {
      Sentry.captureException(e);
      return {};
    }
  }

  static void setupNotificationHandlers() {
    try {
      // Handle notification clicks
      OneSignal.Notifications.addClickListener((event) {
        _print('Notification clicked: ${event.notification}');
        // Handle navigation based on notification data
      });

      // Handle foreground notifications
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        _print('Foreground notification: ${event.notification}');
        // You can customize how notifications appear in foreground
      });

      // Handle permission changes
      OneSignal.Notifications.addPermissionObserver((state) {
        _print('Permission changed: $state');
      });
    } catch (e) {
      Sentry.captureException(e);
    }
  }

  static void _print(String s) {
    Sentry.logger.info("NOTIFICATIONS: $s");
  }
}
