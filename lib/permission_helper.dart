import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart';

class PermissionHelper {
  static void requestNotificationPermission(BuildContext? context) async {
    try {
      // For Android 13+ (API 33+), we need to use the permission handler
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;

        if (status.isDenied || status.isPermanentlyDenied) {
          // Show custom explanation dialog
          final shouldRequest = context == null ? true : await _showPermissionDialog(context);
          if (shouldRequest) {
            final result = await Permission.notification.request();
            _print('Notification permission granted result: $result');
          }
          _print('Notification permission denied');
        } else if (status.isGranted) {
          _print('Notification permission granted already');
        }
      }

      // For other platforms or as fallback, use OneSignal's method
      _requestNotificationPermission();
    } catch (e) {
      _print('Permission request error: $e');
    }
  }

  static Future<bool> _showPermissionDialog(BuildContext context) async {
    try {
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Enable Notifications'),
              content: Text('Once or twice per year, we want to send you free token lottery notifications!'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Not Now')),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Allow')),
              ],
            ),
          ) ??
          false;
    } catch (e) {
      Sentry.captureException(e);
      return true;
    }
  }

  static Future<void> _requestNotificationPermission() async {
    try {
      // Check current permission status
      final status = OneSignal.Notifications.permission;

      if (status == false) {
        // Request permission if not granted
        final granted = await OneSignal.Notifications.requestPermission(true);

        if (granted) {
          _print('Notification permission granted');
        } else {
          _print('Notification permission denied');
        }
      } else {
        _print('Notification permission already granted');
      }
    } catch (e) {
      Sentry.captureException(e);
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
