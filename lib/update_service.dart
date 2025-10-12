// lib/services/update_service.dart
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart'; // ADD THIS
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final bool updateAvailable;
  final String currentVersion;
  final String latestVersion;
  final DateTime lastReminderTime;
  final String? expectedSha256; // From checksum.txt

  UpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    required this.lastReminderTime,
    this.expectedSha256,
  });

  UpdateInfo copyWith({
    bool? updateAvailable,
    String? currentVersion,
    String? latestVersion,
    DateTime? lastReminderTime,
    String? expectedSha256,
  }) {
    return UpdateInfo(
      updateAvailable: updateAvailable ?? this.updateAvailable,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      lastReminderTime: lastReminderTime ?? this.lastReminderTime,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
    );
  }
}

class UpdateService {
  static const String baseUrl = "https://mahakka-apk.vercel.app/";
  static const String versionCheckUrl = '${baseUrl}version.txt';
  static const String checksumUrl = '${baseUrl}checksum.txt';
  static const String apkUrlPointer = '${baseUrl}apk-url.txt';
  static const String lastUpdateReminderKey = 'last_update_reminder';
  static const Duration reminderCooldown = Duration(hours: 12);
  static const Duration checkInterval = Duration(seconds: 60);

  String get currentAbi {
    // Release mode: build-time ABI
    if (kReleaseMode) {
      return const String.fromEnvironment('ABI', defaultValue: 'arm64-v8a');
    }

    // Debug mode: sensible default
    return 'arm64-v8a'; // or 'armeabi-v7a' if testing older devices
  }

  get currentVersion {
    return "4.3.17-BCH";
  }

  // Get APK URL from server
  Future<String?> getApkDownloadUrl() async {
    try {
      final response = await http.get(Uri.parse(apkUrlPointer));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      print('Failed to fetch APK URL: $e');
    }
    return null;
  }

  // Get expected SHA256 from server
  Future<String?> getExpectedSha256() async {
    try {
      final response = await http.get(Uri.parse(checksumUrl));
      if (response.statusCode == 200) {
        return response.body.trim().toLowerCase();
      }
    } catch (e) {
      print('Failed to fetch checksum: $e');
    }
    return null;
  }

  // Check for updates including SHA256
  Future<UpdateInfo> checkForUpdates() async {
    try {
      final versionResponse = await http.get(Uri.parse(versionCheckUrl));

      final prefs = await SharedPreferences.getInstance();
      final lastReminderMillis = prefs.getInt(lastUpdateReminderKey) ?? 0;
      final lastReminderTime = DateTime.fromMillisecondsSinceEpoch(lastReminderMillis);

      if (versionResponse.statusCode == 200) {
        final String latestVersion = versionResponse.body.trim();
        final updateAvailable = _isNewVersionAvailable(currentVersion, latestVersion);

        // Get expected SHA256 if update is available
        String? expectedSha256;
        if (updateAvailable) {
          expectedSha256 = await getExpectedSha256();
        }

        print('Update check: Current=$currentVersion, Latest=$latestVersion, UpdateAvailable=$updateAvailable');

        return UpdateInfo(
          updateAvailable: updateAvailable,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          lastReminderTime: lastReminderTime,
          expectedSha256: expectedSha256,
        );
      }

      return UpdateInfo(
        updateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        lastReminderTime: lastReminderTime,
      );
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final lastReminderMillis = prefs.getInt(lastUpdateReminderKey) ?? 0;
      final lastReminderTime = DateTime.fromMillisecondsSinceEpoch(lastReminderMillis);

      print('Update check error: $e');

      return UpdateInfo(
        updateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        lastReminderTime: lastReminderTime,
      );
    }
  }

  // Calculate SHA256 of downloaded file
  String calculateSha256(File file) {
    final bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  // Verify SHA256 against expected value
  bool verifySha256(File file, String expectedSha256) {
    final calculatedSha256 = calculateSha256(file);
    print('SHA256 Verification: Calculated=$calculatedSha256, Expected=$expectedSha256');
    return calculatedSha256 == expectedSha256.toLowerCase();
  }

  // Manual SHA256 verification with user input
  bool verifyManualSha256(File file, String userSha256) {
    final calculatedSha256 = calculateSha256(file);
    print('Manual SHA256: Calculated=$calculatedSha256, User=$userSha256');
    return calculatedSha256 == userSha256.toLowerCase().trim();
  }

  Future<void> saveReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastUpdateReminderKey, DateTime.now().millisecondsSinceEpoch);
  }

  bool shouldShowReminder(UpdateInfo updateInfo) {
    if (!updateInfo.updateAvailable) return false;

    final timeSinceLastReminder = DateTime.now().difference(updateInfo.lastReminderTime);
    return timeSinceLastReminder > reminderCooldown;
  }

  bool _isNewVersionAvailable(String installedVersion, String remoteVersion) {
    // try {
    //   final installedParts = installedVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    //   final remoteParts = remoteVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    //
    //   for (int i = 0; i < remoteParts.length; i++) {
    //     if (i >= installedParts.length) return true;
    //     if (remoteParts[i] > installedParts[i]) return true;
    //     if (remoteParts[i] < installedParts[i]) return false;
    //   }
    return installedVersion != remoteVersion;
    // } catch (e) {
    //   print('Version comparison error: $e');
    //   return false;
    // }
  }

  // Enhanced download with SHA256 verification
  Future<void> downloadAndInstallApk({
    required Function(int bytes, int total) onProgress,
    required Function onComplete,
    required Function(String error) onError,
    required String? expectedSha256,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        onError('Storage permission required to download update');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/app_update_${DateTime.now().millisecondsSinceEpoch}.apk');

      final apkUrl = await getApkDownloadUrl();
      if (apkUrl == null) {
        onError('Failed to get APK download URL');
        return;
      }
      final request = await http.get(Uri.parse(apkUrl));
      // final request = await http.get(Uri.parse("${baseUrl}apk/mahakka_com-${latestVersion}.apk"));
      final bytes = request.bodyBytes;

      await file.writeAsBytes(bytes);

      // Verify SHA256 if provided
      if (expectedSha256 != null && expectedSha256.isNotEmpty) {
        final isValid = verifySha256(file, expectedSha256);
        if (!isValid) {
          await file.delete(); // Delete suspicious file
          onError('Security check failed: SHA256 mismatch');
          return;
        }
      }

      onComplete();
      await installApk(file);
    } catch (e) {
      onError('Download failed: $e');
    }
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> installApk(File apkFile) async {
    try {
      final result = await OpenFile.open(apkFile.path);

      if (result.type != ResultType.done) {
        throw Exception('Failed to open APK file: ${result.message}');
      }
    } catch (e) {
      throw Exception('Installation failed: $e');
    }
  }
}

// Providers remain the same
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateInfoProvider = StateProvider<UpdateInfo>((ref) {
  return UpdateInfo(
    updateAvailable: false,
    currentVersion: '1.0.0',
    latestVersion: '1.0.0',
    lastReminderTime: DateTime.now().subtract(Duration(hours: 13)),
  );
});

// final updateCheckProvider = StreamProvider.autoDispose<void>((ref) async* {
//   final updateService = ref.read(updateServiceProvider);
//
//   while (true) {
//     await Future.delayed(UpdateService.checkInterval);
//
//     final updateInfo = await updateService.checkForUpdates();
//     ref.read(updateInfoProvider.notifier).state = updateInfo;
//
//     yield;
//   }
// });

// Traditional stream provider without autoDispose and yield
final updateCheckProvider = StreamProvider<void>((ref) {
  final updateService = ref.read(updateServiceProvider);
  final StreamController<void> controller = StreamController<void>();
  // bool isDisposed = false;

  Future<void> checkUpdatesPeriodically() async {
    // while (!isDisposed) {
    await Future.delayed(UpdateService.checkInterval);

    // if (isDisposed) break;

    try {
      final updateInfo = await updateService.checkForUpdates();
      ref.read(updateInfoProvider.notifier).state = updateInfo;
      controller.add(null);
    } catch (e) {
      print('Update check error in stream: $e');
    }
    // }
  }

  // Start the periodic checking
  checkUpdatesPeriodically();

  // Cleanup when the provider is disposed
  ref.onDispose(() {
    // isDisposed = true;
    controller.close();
  });

  return controller.stream;
});
