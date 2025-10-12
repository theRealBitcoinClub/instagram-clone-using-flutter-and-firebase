// lib/services/update_service.dart
import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  final String? expectedSha256;
  final String detectedAbi;

  UpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    required this.lastReminderTime,
    this.expectedSha256,
    required this.detectedAbi,
  });

  UpdateInfo copyWith({
    bool? updateAvailable,
    String? currentVersion,
    String? latestVersion,
    DateTime? lastReminderTime,
    String? expectedSha256,
    String? detectedAbi,
  }) {
    return UpdateInfo(
      updateAvailable: updateAvailable ?? this.updateAvailable,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      lastReminderTime: lastReminderTime ?? this.lastReminderTime,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
      detectedAbi: detectedAbi ?? this.detectedAbi,
    );
  }

  @override
  String toString() {
    return 'UpdateInfo{'
        'updateAvailable: $updateAvailable, '
        'currentVersion: $currentVersion, '
        'latestVersion: $latestVersion, '
        'lastReminderTime: $lastReminderTime, '
        'expectedSha256: $expectedSha256, '
        'detectedAbi: $detectedAbi'
        '}';
  }
}

class UpdateService {
  static const String baseUrl = "https://mahakka-apk.vercel.app/";
  static const String lastUpdateReminderKey = 'last_update_reminder';
  static const Duration reminderCooldown = Duration(hours: 12);
  static const Duration checkInterval = Duration(seconds: 60);

  // Build-time ABI - 100% reliable
  String get currentAbi {
    if (kReleaseMode) {
      return const String.fromEnvironment('ABI', defaultValue: 'arm64-v8a');
    }
    return 'arm64-v8a';
  }

  String get currentVersion => "4.3.14-BCH";

  // URL construction using version folders and ABI-specific files
  String getVersionCheckUrl() => '$baseUrl/version.txt';

  String getChecksumUrl(String version) => '$baseUrl$version/checksum-$currentAbi.txt';

  String getApkUrl(String version) => '$baseUrl$version/mahakka_com-$version-$currentAbi.apk';

  // Fallback URL if ABI-specific file doesn't exist
  String getFallbackApkUrl(String version) => '$baseUrl$version/apk-url.txt';

  // Get expected SHA256 for current ABI
  Future<String?> getExpectedSha256(String version) async {
    try {
      final response = await http.get(Uri.parse(getChecksumUrl(version)));
      if (response.statusCode == 200) {
        return response.body.trim().toLowerCase();
      }

      // If ABI-specific checksum not found, try generic fallback
      final fallbackResponse = await http.get(Uri.parse('$baseUrl$version/checksum.txt'));
      if (fallbackResponse.statusCode == 200) {
        return fallbackResponse.body.trim().toLowerCase();
      }
    } catch (e) {
      _print('Failed to fetch checksum: $e');
    }
    return null;
  }

  // Check for updates including SHA256 and ABI info
  Future<UpdateInfo> checkForUpdates() async {
    try {
      final versionResponse = await http.get(Uri.parse(getVersionCheckUrl()));

      final prefs = await SharedPreferences.getInstance();
      final lastReminderMillis = prefs.getInt(lastUpdateReminderKey) ?? 0;
      final lastReminderTime = DateTime.fromMillisecondsSinceEpoch(lastReminderMillis);

      if (versionResponse.statusCode == 200) {
        final String latestVersion = versionResponse.body.trim();
        final updateAvailable = _isNewVersionAvailable(currentVersion, latestVersion);

        // Get expected SHA256 if update is available
        String? expectedSha256;
        if (updateAvailable) {
          expectedSha256 = await getExpectedSha256(latestVersion);
        }

        _print('Update check: Current=$currentVersion, Latest=$latestVersion, UpdateAvailable=$updateAvailable, ABI=$currentAbi');

        return UpdateInfo(
          updateAvailable: updateAvailable,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          lastReminderTime: lastReminderTime,
          expectedSha256: expectedSha256,
          detectedAbi: currentAbi,
        );
      }

      return UpdateInfo(
        updateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        lastReminderTime: lastReminderTime,
        detectedAbi: currentAbi,
      );
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final lastReminderMillis = prefs.getInt(lastUpdateReminderKey) ?? 0;
      final lastReminderTime = DateTime.fromMillisecondsSinceEpoch(lastReminderMillis);

      _print('Update check error: $e');

      return UpdateInfo(
        updateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        lastReminderTime: lastReminderTime,
        detectedAbi: currentAbi,
      );
    }
  }

  // Get APK URL with fallback mechanism
  Future<String> getApkDownloadUrl(String version) async {
    try {
      // First, verify the ABI-specific APK exists by checking its checksum
      final checksumResponse = await http.get(Uri.parse(getChecksumUrl(version)));

      if (checksumResponse.statusCode == 200) {
        _print('✅ Using ABI-specific URL for $currentAbi');
        return getApkUrl(version);
      } else {
        // Fallback to generic APK URL
        _print('⚠️ ABI-specific APK not found, using fallback');
        return await _getFallbackApkUrl(version);
      }
    } catch (e) {
      _print('APK URL detection failed: $e');
      return await _getFallbackApkUrl(version);
    }
  }

  Future<String> _getFallbackApkUrl(String version) async {
    try {
      final response = await http.get(Uri.parse(getFallbackApkUrl(version)));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      _print('Fallback APK URL failed: $e');
    }

    // Ultimate fallback - direct URL (you can set this in apk-url.txt)
    return 'https://drive.usercontent.google.com/u/0/uc?id=YOUR_FILE_ID&export=download';
  }

  // Enhanced download with ABI-specific URLs
  Future<void> downloadAndInstallApk({
    required String latestVersion,
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

      // Get the appropriate APK URL
      final apkUrl = await getApkDownloadUrl(latestVersion);
      _print('📥 Downloading from: $apkUrl');

      final request = await http.get(Uri.parse(apkUrl));
      final bytes = request.bodyBytes;

      await file.writeAsBytes(bytes);

      // Verify SHA256 if provided
      if (expectedSha256 != null && expectedSha256.isNotEmpty) {
        final isValid = verifySha256(file, expectedSha256);
        if (!isValid) {
          await file.delete();
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

  void _print(String s) {
    if (kDebugMode) print("UPDATESERVICE: " + s);
  }

  // ... REST OF YOUR EXISTING METHODS REMAIN THE SAME ...
  // calculateSha256, verifySha256, verifyManualSha256, saveReminderTime,
  // shouldShowReminder, _isNewVersionAvailable, _requestStoragePermission, installApk

  // Calculate SHA256 of downloaded file
  String calculateSha256(File file) {
    final bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  // Verify SHA256 against expected value
  bool verifySha256(File file, String expectedSha256) {
    final calculatedSha256 = calculateSha256(file);
    _print('SHA256 Verification: Calculated=$calculatedSha256, Expected=$expectedSha256');
    return calculatedSha256 == expectedSha256.toLowerCase();
  }

  // Manual SHA256 verification with user input
  bool verifyManualSha256(File file, String userSha256) {
    final calculatedSha256 = calculateSha256(file);
    _print('Manual SHA256: Calculated=$calculatedSha256, User=$userSha256');
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
    return installedVersion != remoteVersion;
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> installApk(File apkFile) async {
    try {
      if (Platform.isAndroid) {
        final result = await OpenFile.open(apkFile.path);
        if (result.type != ResultType.done) {
          throw Exception('Failed to open APK file: ${result.message}');
        }
      }
    } catch (e) {
      // Fallback to manual installation intent if needed
      _print('OpenFile failed, trying manual installation: $e');
      await _installApkManually(apkFile);
    }
  }

  Future<void> _installApkManually(File apkFile) async {
    // You can implement manual installation intent here if needed
    _print('Manual installation required for: ${apkFile.path}');
  }
}

// Updated providers
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateInfoProvider = StateProvider<UpdateInfo>((ref) {
  return UpdateInfo(
    updateAvailable: false,
    currentVersion: '1.0.0',
    latestVersion: '1.0.0',
    lastReminderTime: DateTime.now(),
    detectedAbi: 'arm64-v8a',
  );
});

final updateCheckProvider = StateProvider<void>((ref) {
  final updateService = ref.read(updateServiceProvider);

  // Set up periodic checking
  final timer = Timer.periodic(UpdateService.checkInterval, (_) {
    _performUpdateCheck(updateService, ref);
  });

  ref.onDispose(() => timer.cancel());

  // Initial check
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _performUpdateCheck(updateService, ref);
  });

  return null;
});

// Helper function to perform the update check
Future<void> _performUpdateCheck(UpdateService updateService, Ref ref) async {
  try {
    if (kDebugMode) print('Updatecheck');
    final updateInfo = await updateService.checkForUpdates();

    if (kDebugMode) print('Updatecheck $updateInfo');
    ref.read(updateInfoProvider.notifier).state = updateInfo;
  } catch (e) {
    if (kDebugMode) print('Updatecheck check error in stream: $e');
  }
}
