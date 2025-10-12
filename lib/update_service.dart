import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const Duration checkInterval = Duration(seconds: 300);
  static const int requiredFreeSpaceMB = 111; // 222MB buffer for APK + app operation

  // Build-time ABI - 100% reliable
  String get currentAbi {
    if (kReleaseMode) {
      return const String.fromEnvironment('ABI', defaultValue: 'arm64-v8a');
    }
    return 'arm64-v8a';
  }

  String get currentVersion => "4.3.17-BCH";

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

  // // Check available space in temp directory
  // Future<bool> _hasEnoughSpace() async {
  //   try {
  //     final tempDir = await getTemporaryDirectory();
  //     final stat = await tempDir.stat();
  //
  //     // Calculate available space (in bytes)
  //     final availableSpace = stat.freeSpace;
  //     final requiredSpace = requiredFreeSpaceMB * 1024 * 1024; // Convert MB to bytes
  //
  //     _print(
  //       'Storage check - Available: ${(availableSpace / (1024 * 1024)).toStringAsFixed(2)}MB, '
  //       'Required: ${requiredFreeSpaceMB}MB',
  //     );
  //
  //     return availableSpace >= requiredSpace;
  //   } catch (e) {
  //     _print('Storage check error: $e');
  //     return false; // Assume not enough space if we can't check
  //   }
  // }

  // Check available space in temp directory - Ultra safe version with 1MB chunks
  Future<bool> _hasEnoughSpace() async {
    if (!Platform.isAndroid) return true;

    final List<File> testFiles = [];

    try {
      final tempDir = await getTemporaryDirectory();

      _print('Starting 222MB storage space verification...');

      const totalRequiredMB = 222;
      const filesCount = 10;
      const fileSizeMB = 22.2;
      var fileSizeBytes = (fileSizeMB * 1024 * 1024).round();
      const chunkSize = 1 * 1024 * 1024; // Ultra safe 1MB chunks

      // Create a reusable 1MB chunk of zeros
      final chunkData = List.filled(chunkSize, 0);

      for (int fileIndex = 0; fileIndex < filesCount; fileIndex++) {
        final testFile = File('${tempDir.path}/space_check_${DateTime.now().millisecondsSinceEpoch}_$fileIndex.tmp');
        testFiles.add(testFile);

        _print('Creating file ${fileIndex + 1}/$filesCount (${fileSizeMB}MB)...');

        final sink = testFile.openWrite();
        int writtenBytes = 0;

        while (writtenBytes < fileSizeBytes) {
          final remainingBytes = fileSizeBytes - writtenBytes;
          final currentChunkSize = remainingBytes < chunkSize ? remainingBytes : chunkSize;

          sink.add(chunkData.sublist(0, currentChunkSize));
          writtenBytes += currentChunkSize;

          // Flush every 10MB written
          if (writtenBytes % (10 * 1024 * 1024) == 0) {
            await sink.flush();
          }
        }

        await sink.flush();
        await sink.close();

        // Verify file size
        final actualFileSize = await testFile.length();
        final success = actualFileSize >= fileSizeBytes;

        if (!success) {
          _print('❌ File ${fileIndex + 1} failed: ${(actualFileSize / (1024 * 1024)).toStringAsFixed(1)}MB < ${fileSizeMB}MB');
          return false;
        }

        _print('✅ File ${fileIndex + 1}: ${(actualFileSize / (1024 * 1024)).toStringAsFixed(1)}MB');
      }

      _print('🎉 SUCCESS: 222MB storage verified with ${filesCount} files');
      return true;
    } catch (e) {
      _print('❌ Storage verification failed: $e');
      return false;
    } finally {
      // Cleanup all files
      _print('Cleaning up test files...');
      for (final testFile in testFiles) {
        try {
          if (await testFile.exists()) {
            await testFile.delete();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      }
      _print('Cleanup completed');
    }
  }

  // Enhanced download with space checking and temp directory usage - File streaming version
  Future<void> downloadAndInstallApk({
    required String latestVersion,
    required Function(int bytes, int total) onProgress,
    required Function onComplete,
    required Function(String error) onError,
    required String? expectedSha256,
  }) async {
    final client = http.Client();
    File? file;

    try {
      // Check available space first
      if (!await _hasEnoughSpace()) {
        onError('Insufficient storage space. Please free up at least ${requiredFreeSpaceMB}MB and try again.');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      file = File('${tempDir.path}/mahakka_update_$latestVersion.apk');

      // Get the appropriate APK URL
      final apkUrl = await getApkDownloadUrl(latestVersion);
      _print('📥 Downloading from: $apkUrl');

      // Use streaming download for progress tracking and memory efficiency
      final request = http.Request('GET', Uri.parse(apkUrl));
      final streamedResponse = await client.send(request);

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();

      await for (var chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }

      await sink.close();
      _print('Download completed: ${file.lengthSync()} bytes');

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
    } catch (e) {
      // Clean up partial file on error
      if (file != null && await file.exists()) {
        await file.delete();
      }
      onError('Download failed: $e');
    } finally {
      client.close();
    }
  }

  void _print(String s) {
    if (kDebugMode) print("UPDATESERVICE: " + s);
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

  Future<void> installApk(File apkFile, ctx) async {
    try {
      if (Platform.isAndroid) {
        _print('Attempting to install APK: ${apkFile.path}');

        // Ensure we have the install permission first
        if (!await _requestStoragePermission()) {
          throw Exception('Install permission not granted. Please enable "Install unknown apps" for Mahakka in system settings.');
        }

        // Try with OpenFile
        final result = await OpenFile.open(apkFile.path);
        _print('OpenFile result: ${result.type} - ${result.message}');

        if (result.type == ResultType.done) {
          _print('APK installation launched successfully');
          return;
        } else if (result.type == ResultType.noAppToOpen) {
          throw Exception('No app found to handle APK installation. This device may not support APK installation.');
        } else if (result.type == ResultType.permissionDenied) {
          throw Exception('Permission denied. Please enable "Install unknown apps" for Mahakka in system settings.');
        } else {
          throw Exception('Installation failed: ${result.message}');
        }
      }
    } catch (e) {
      _print('APK installation failed: $e');
      await _showInstallationInstructions(ctx);
      rethrow; // Re-throw to let the caller handle it
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      if (!Platform.isAndroid) return true;

      // For Android 8.0+, we need REQUEST_INSTALL_PACKAGES permission
      final installStatus = await Permission.requestInstallPackages.status;
      _print('Current install permission status: $installStatus');

      if (installStatus.isDenied || installStatus.isPermanentlyDenied) {
        _print('Requesting REQUEST_INSTALL_PACKAGES permission...');
        final result = await Permission.requestInstallPackages.request();
        _print('REQUEST_INSTALL_PACKAGES permission result: $result');
        return result.isGranted;
      }

      return installStatus.isGranted;
    } catch (e) {
      _print('Permission request error: $e');
      return false;
    }
  }

  Future<void> _showInstallationInstructions(BuildContext context) async {
    final tempDir = await getTemporaryDirectory();
    final apkFiles = Directory(tempDir.path).listSync().where((file) {
      return file.path.contains('mahakka_update_') && file.path.endsWith('.apk');
    }).toList();

    final latestApk = apkFiles.isNotEmpty ? File(apkFiles.last.path) : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: Colors.orange),
            SizedBox(width: 12),
            Text('Installation Permission Required', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To install the update, you need to enable "Install unknown apps" permission for Mahakka.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 Steps to enable:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  SizedBox(height: 8),
                  Text('1. Tap "Open Settings" below'),
                  Text('2. Find "Mahakka" in the list'),
                  Text('3. Enable "Allow from this source"'),
                  Text('4. Return here and try again'),
                ],
              ),
            ),
            if (latestApk != null) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text('Alternative Manual Installation:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: latestApk.path));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('APK path copied to clipboard')));
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          latestApk.path,
                          style: TextStyle(fontSize: 10, fontFamily: 'Monospace'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.copy, size: 16),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to copy path, then use a file manager to find and install this file',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    try {
      _print('Opening app settings...');
      await openAppSettings();
    } catch (e) {
      _print('Failed to open app settings: $e');
      // Fallback: open general settings
      try {
        await AndroidIntent(action: 'android.settings.APPLICATION_DETAILS_SETTINGS', data: 'package:com.mahakka').launch();
      } catch (e2) {
        _print('Failed to open specific app settings: $e2');
      }
    }
  }
}

// Updated providers using NotifierProvider
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final updateInfoProvider = NotifierProvider<UpdateInfoNotifier, UpdateInfo>(UpdateInfoNotifier.new);

class UpdateInfoNotifier extends Notifier<UpdateInfo> {
  Timer? _timer;

  @override
  UpdateInfo build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    final updateService = ref.read(updateServiceProvider);

    // Initial state
    final initialInfo = UpdateInfo(
      updateAvailable: false,
      currentVersion: updateService.currentVersion,
      latestVersion: updateService.currentVersion,
      lastReminderTime: DateTime.now(),
      detectedAbi: updateService.currentAbi,
    );

    // Set up periodic checking
    _startPeriodicChecks(updateService);

    return initialInfo;
  }

  void _startPeriodicChecks(UpdateService updateService) {
    // Cancel existing timer
    _timer?.cancel();

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performUpdateCheck(updateService);
    });

    // Periodic checks
    _timer = Timer.periodic(UpdateService.checkInterval, (_) {
      _performUpdateCheck(updateService);
    });
  }

  Future<void> _performUpdateCheck(UpdateService updateService) async {
    try {
      if (kDebugMode) print('Update check');
      final updateInfo = await updateService.checkForUpdates();

      if (kDebugMode) print('Update result: $updateInfo');
      state = updateInfo;
    } catch (e) {
      if (kDebugMode) print('Update check error: $e');
    }
  }
}
