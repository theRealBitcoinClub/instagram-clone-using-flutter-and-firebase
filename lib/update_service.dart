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
import 'package:sentry_flutter/sentry_flutter.dart';

class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String? expectedSha256;

  UpdateInfo({required this.currentVersion, required this.latestVersion, this.expectedSha256});

  UpdateInfo copyWith({String? currentVersion, String? latestVersion, String? expectedSha256}) {
    return UpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      expectedSha256: expectedSha256 ?? this.expectedSha256,
    );
  }

  bool get isUpdateAvailable {
    return kDebugMode ? false : currentVersion != latestVersion;
  }

  @override
  String toString() {
    return 'UpdateInfo{'
        'currentVersion: $currentVersion, '
        'latestVersion: $latestVersion, '
        'expectedSha256: $expectedSha256, '
        '}';
  }
}

class UpdateService {
  static const String baseUrl = "https://mahakka-apk.vercel.app/";
  static const Duration checkInterval = Duration(seconds: 90);
  static const int requiredFreeSpaceMB = 111; // 222MB buffer for APK + app operation

  // Build-time ABI - 100% reliable
  String get currentAbi {
    if (kReleaseMode) {
      return const String.fromEnvironment('ABI', defaultValue: 'arm64-v8a');
    }
    return 'arm64-v8a';
  }

  String get currentVersion => "4.5.27-BCH";

  // URL construction using version folders and ABI-specific files
  String getVersionCheckUrl() => '$baseUrl/version.txt';

  String getChecksumUrl(String version) => '$baseUrl$version/checksum-$currentAbi.txt';

  String getApkUrl(String version) => '$baseUrl$version/mahakka_com-$version-$currentAbi.apk';

  // Fallback URL if ABI-specific file doesn't exist
  String getFallbackApkUrl(String version) => '$baseUrl$version/apk-url.txt';

  http.Client createNonCachingClient() {
    return http.Client();
  }

  Future<String?> getExpectedSha256(String version) async {
    final client = createNonCachingClient();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final headers = {'Cache-Control': 'no-cache, no-store, must-revalidate', 'Pragma': 'no-cache', 'Expires': '0'};

      final response = await client.get(Uri.parse('${getChecksumUrl(version)}?t=$timestamp'), headers: headers);

      if (response.statusCode == 200) {
        return response.body.trim().toLowerCase();
      }

      final fallbackResponse = await client.get(Uri.parse('$baseUrl$version/checksum.txt?t=$timestamp'), headers: headers);

      if (fallbackResponse.statusCode == 200) {
        return fallbackResponse.body.trim().toLowerCase();
      }
    } catch (e) {
      _print('Failed to fetch checksum: $e');
    } finally {
      client.close(); // Always close the client
    }
    return null;
  }

  // // Get expected SHA256 for current ABI
  // Future<String?> getExpectedSha256(String version) async {
  //   try {
  //     final response = await http.get(Uri.parse(getChecksumUrl(version)));
  //     if (response.statusCode == 200) {
  //       return response.body.trim().toLowerCase();
  //     }
  //
  //     // If ABI-specific checksum not found, try generic fallback
  //     final fallbackResponse = await http.get(Uri.parse('$baseUrl$version/checksum.txt'));
  //     if (fallbackResponse.statusCode == 200) {
  //       return fallbackResponse.body.trim().toLowerCase();
  //     }
  //   } catch (e) {
  //     _print('Failed to fetch checksum: $e');
  //   }
  //   return null;
  // }

  void debugSha256Verification(File file, String expectedSha256) {
    final calculated = calculateSha256Sync(file);
    Sentry.logger.debug("UPDATE SERVICE expectedSha256 $expectedSha256");
    // print('=== SHA256 DEBUG ===');
    // print('Expected: "$expectedSha256" (length: ${expectedSha256?.length})');
    // print('Calculated: "$calculated" (length: ${calculated.length})');
    // print('Expected (lower): "${expectedSha256?.toLowerCase()}"');
    // print('Calculated (lower): "${calculated.toLowerCase()}"');
    // print('Match: ${calculated.toLowerCase() == expectedSha256?.toLowerCase()}');
    // print('===================');
  }

  // Check for updates including SHA256 and ABI info
  Future<UpdateInfo> checkForUpdates() async {
    try {
      final versionResponse = await http.get(Uri.parse(getVersionCheckUrl()));

      if (versionResponse.statusCode == 200) {
        final String latestVersion = versionResponse.body.trim();
        final updateAvailable = _isNewVersionAvailable(currentVersion, latestVersion);

        // Get expected SHA256 if update is available
        String? expectedSha256;
        if (updateAvailable) {
          expectedSha256 = await getExpectedSha256(latestVersion);
        }

        _print('Update check: Current=$currentVersion, Latest=$latestVersion, UpdateAvailable=$updateAvailable, ABI=$currentAbi');

        return UpdateInfo(currentVersion: currentVersion, latestVersion: latestVersion, expectedSha256: expectedSha256);
      }

      return UpdateInfo(currentVersion: currentVersion, latestVersion: currentVersion);
    } catch (e) {
      _print('Update check error: $e');
      return UpdateInfo(currentVersion: currentVersion, latestVersion: currentVersion);
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

  // Enhanced download with robust file management
  Future<void> downloadAndInstallApk({
    required String latestVersion,
    required Function(int bytes, int total) onProgress,
    required Function onComplete,
    required Function(String error) onError,
    required String? expectedSha256,
  }) async {
    final client = http.Client();
    File? tempFile;
    File? finalFile;

    try {
      // Check available space first
      if (!await _hasEnoughSpace()) {
        onError('Insufficient storage space. Please free up at least ${requiredFreeSpaceMB}MB and try again.');
        return;
      }

      final tempDir = await getTemporaryDirectory();

      // Define file paths - using .tmp during download
      final tempFilePath = '${tempDir.path}/mahakka_update_$latestVersion.tmp';
      final finalFilePath = '${tempDir.path}/mahakka_update_$latestVersion.apk';

      tempFile = File(tempFilePath);
      finalFile = File(finalFilePath);

      // Clean up any existing temp files from previous attempts
      await _cleanupPreviousDownloads(tempDir, latestVersion);

      // Get the appropriate APK URL
      final apkUrl = await getApkDownloadUrl(latestVersion);
      _print('📥 Downloading from: $apkUrl');

      // Use streaming download for progress tracking and memory efficiency
      final request = http.Request('GET', Uri.parse(apkUrl));
      final streamedResponse = await client.send(request);

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      // Download to .tmp file
      final sink = tempFile.openWrite();

      await for (var chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }

      await sink.close();
      _print('Download completed: ${tempFile.lengthSync()} bytes');

      // Verify the temp file exists and has content
      if (!await tempFile.exists() || await tempFile.length() == 0) {
        throw Exception('Downloaded file is empty or missing');
      }

      // Verify SHA256 if provided
      if (expectedSha256 != null && expectedSha256.isNotEmpty) {
        final isValid = await verifySha256(tempFile, expectedSha256);
        if (!isValid) {
          // await _safeDelete(tempFile);
          onError('Security check failed: SHA256 mismatch. The downloaded file may be corrupted.');
          return;
        }
        _print('✅ SHA256 verification passed');
      }

      // Rename from .tmp to .apk after successful verification
      try {
        await tempFile.rename(finalFilePath);
        _print('✅ File renamed from .tmp to .apk');

        // Verify the final file exists
        if (!await finalFile.exists()) {
          throw Exception('Failed to create final APK file');
        }
      } catch (e) {
        // If rename fails (cross-device), copy and delete original
        _print('Rename failed, copying file: $e');
        await tempFile.copy(finalFilePath);
        await _safeDelete(tempFile);
      }

      onComplete();
    } catch (e) {
      // Clean up any partial files on error
      await _safeDelete(tempFile);
      await _safeDelete(finalFile);
      onError('Download failed: $e');
    } finally {
      client.close();
    }
  }

  // Safe file deletion that ignores errors
  Future<void> _safeDelete(File? file) async {
    if (file == null) return;

    try {
      if (await file.exists()) {
        await file.delete();
        _print('🗑️ Deleted file: ${file.path}');
      }
    } catch (e) {
      _print('⚠️ Could not delete file ${file.path}: $e');
      // Don't throw - we don't want cleanup failures to break the flow
    }
  }

  // Clean up previous download attempts
  Future<void> _cleanupPreviousDownloads(Directory tempDir, String version) async {
    try {
      final files = await tempDir.list().toList();

      for (var file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          // Delete any .tmp files or previous APK files for this version
          if (fileName.contains('mahakka_update_$version') && (fileName.endsWith('.tmp') || fileName.endsWith('.apk'))) {
            await _safeDelete(file);
          }
        }
      }
      _print('🧹 Cleaned up previous download attempts for version $version');
    } catch (e) {
      _print('⚠️ Cleanup of previous downloads failed: $e');
      // Continue anyway - this shouldn't block the download
    }
  }

  // Enhanced installation with guaranteed cleanup
  Future<void> installApkWithCleanup({
    required String latestVersion,
    required BuildContext context,
    required Function(String error) onError,
    required Function onSuccess,
  }) async {
    File? apkFile;

    try {
      final tempDir = await getTemporaryDirectory();
      final apkFilePath = '${tempDir.path}/mahakka_update_$latestVersion.apk';
      apkFile = File(apkFilePath);

      // Verify file exists before installation
      if (!await apkFile.exists()) {
        throw Exception('APK file not found. Please download the update again.');
      }

      // Verify file is not empty
      final fileSize = await apkFile.length();
      if (fileSize == 0) {
        throw Exception('APK file is empty. Please download the update again.');
      }

      _print('🔧 Installing APK: ${apkFile.path} (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)');

      // Ensure we have the install permission first
      if (!await _requestStoragePermission()) {
        throw Exception('Install permission not granted. Please enable "Install unknown apps" for Mahakka in system settings.');
      }

      // Try with OpenFile
      final result = await OpenFile.open(apkFile.path);
      _print('OpenFile result: ${result.type} - ${result.message}');

      if (result.type == ResultType.done) {
        _print('✅ APK installation launched successfully');
        onSuccess();

        // Schedule cleanup after a delay to ensure installation has started
        Future.delayed(Duration(seconds: 5), () async {
          await _safeDelete(apkFile);
          _print('🧹 Cleaned up APK file after successful installation launch');
        });
      } else if (result.type == ResultType.noAppToOpen) {
        throw Exception('No app found to handle APK installation. This device may not support APK installation.');
      } else if (result.type == ResultType.permissionDenied) {
        throw Exception('Permission denied. Please enable "Install unknown apps" for Mahakka in system settings.');
      } else {
        throw Exception('Installation failed: ${result.message}');
      }
    } catch (e) {
      // Clean up on installation failure
      await _safeDelete(apkFile);
      _print('❌ Installation failed: $e');
      onError('Installation failed: $e');

      // Show installation instructions for permission issues
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        await _showInstallationInstructions(context, latestVersion);
      }
    }
  }

  // NEW METHOD: Combined download and install with cleanup
  Future<void> downloadAndInstallWithCleanup({
    required String latestVersion,
    required Function(int bytes, int total) onProgress,
    required Function onInstallStarted,
    required Function(String error) onError,
    required BuildContext context,
    required String? expectedSha256,
  }) async {
    await downloadAndInstallApk(
      latestVersion: latestVersion,
      onProgress: onProgress,
      onComplete: () async {
        // Download completed successfully, now install with cleanup
        await installApkWithCleanup(latestVersion: latestVersion, context: context, onError: onError, onSuccess: onInstallStarted);
      },
      onError: onError,
      expectedSha256: expectedSha256,
    );
  }

  // NEW METHOD: Force cleanup of all update files
  Future<void> forceCleanupDownloads() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = await tempDir.list().toList();

      int deletedCount = 0;
      for (var file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          if (fileName.contains('mahakka_update_') && (fileName.endsWith('.tmp') || fileName.endsWith('.apk'))) {
            await _safeDelete(file);
            deletedCount++;
          }
        }
      }
      _print('🧹 Force cleanup completed: $deletedCount files removed');
    } catch (e) {
      _print('⚠️ Force cleanup failed: $e');
    }
  }

  // NEW METHOD: Initialize clean state on app start
  Future<void> initializeCleanState() async {
    await forceCleanupDownloads();
  }

  // Enhanced SHA256 verification with async file reading
  Future<bool> verifySha256(File file, String expectedSha256) async {
    debugSha256Verification(file, expectedSha256);
    try {
      final calculatedSha256 = await calculateSha256(file);
      Sentry.logger.debug("UPDATE SERVICE calculatedSha256 $calculatedSha256");
      _print('SHA256 Verification: Calculated=$calculatedSha256, Expected=$expectedSha256');
      return calculatedSha256 == expectedSha256.toLowerCase();
    } catch (e) {
      _print('SHA256 verification error: $e');
      return false;
    }
  }

  // Async SHA256 calculation for large files
  Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString().toLowerCase();
  }

  void _print(String s) {
    if (kDebugMode) print("UPDATESERVICE: " + s);
  }

  // Calculate SHA256 of downloaded file (keeping original sync version for compatibility)
  String calculateSha256Sync(File file) {
    final bytes = file.readAsBytesSync();
    final digest = sha256.convert(bytes);
    return digest.toString().toLowerCase();
  }

  // Verify SHA256 against expected value (keeping original sync version for compatibility)
  bool verifySha256Sync(File file, String expectedSha256) {
    final calculatedSha256 = calculateSha256Sync(file);
    _print('SHA256 Verification: Calculated=$calculatedSha256, Expected=$expectedSha256');
    return calculatedSha256 == expectedSha256.toLowerCase();
  }

  // Manual SHA256 verification with user input (unchanged)
  bool verifyManualSha256(File file, String userSha256, String previousError) {
    try {
      Sentry.captureEvent(
        SentryEvent(
          message: SentryMessage("Manual SHA256 verification ${file.path}"),
          breadcrumbs: [
            Breadcrumb(message: previousError),
            Breadcrumb(message: userSha256),
          ],
        ),
      );
    } catch (e) {}
    final calculatedSha256 = calculateSha256Sync(file);
    _print('Manual SHA256: Calculated=$calculatedSha256, User=$userSha256');
    return calculatedSha256 == userSha256.toLowerCase().trim();
  }

  bool _isNewVersionAvailable(String installedVersion, String remoteVersion) {
    return installedVersion != remoteVersion;
  }

  // Original installApk method remains unchanged for compatibility
  Future<void> installApk(File apkFile, BuildContext ctx) async {
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
      await _showInstallationInstructions(ctx, "unknown"); // Updated signature
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

  // Updated _showInstallationInstructions with version parameter
  Future<void> _showInstallationInstructions(BuildContext context, String version) async {
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
  final service = UpdateService();
  // Initialize clean state when the service is first created
  WidgetsBinding.instance.addPostFrameCallback((_) {
    service.initializeCleanState();
  });
  return service;
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
    final initialInfo = UpdateInfo(currentVersion: updateService.currentVersion, latestVersion: updateService.currentVersion);

    // Set up periodic checking
    _startPeriodicChecks(updateService);

    return initialInfo;
  }

  void _startPeriodicChecks(UpdateService updateService) {
    // Cancel existing timer
    _timer?.cancel();

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 15), () {
        _performUpdateCheck(updateService);
      });
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
