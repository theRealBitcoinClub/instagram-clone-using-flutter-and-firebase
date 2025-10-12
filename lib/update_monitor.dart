import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/update_dialog.dart';
import 'package:mahakka/update_service.dart';
import 'package:path_provider/path_provider.dart';

class UpdateMonitor extends ConsumerWidget {
  const UpdateMonitor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateInfo = ref.watch(updateInfoProvider);
    final updateService = ref.read(updateServiceProvider);

    // Initialize translations
    final updateAvailableText = ref.watch(autoTranslationTextProvider('Update Available')).value ?? 'Update Available';
    final updateNowText = ref.watch(autoTranslationTextProvider('Tap here')).value ?? 'Tap here';
    final updateButton = ref.watch(autoTranslationTextProvider('UPDATE')).value ?? 'UPDATE';
    final installReadyText = ref.watch(autoTranslationTextProvider('Installation Ready')).value ?? 'Installation Ready';
    final installNowText = ref.watch(autoTranslationTextProvider('Tap to install')).value ?? 'Tap to install';
    final installButton = ref.watch(autoTranslationTextProvider('INSTALL')).value ?? 'INSTALL';

    // Check if we should show update snackbar
    if (updateInfo.updateAvailable && updateService.shouldShowReminder(updateInfo)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final isAlreadyDownloaded = await _isUpdateAlreadyDownloaded(updateInfo.latestVersion);
        if (isAlreadyDownloaded) {
          _showInstallationSnackBar(context, installReadyText, installNowText, installButton, updateInfo.latestVersion);
        } else {
          _showUpdateSnackBar(context, updateAvailableText, updateNowText, updateButton);
        }
      });
    }

    return const SizedBox.shrink();
  }

  Future<bool> _isUpdateAlreadyDownloaded(String latestVersion) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final apkFiles = Directory(tempDir.path).listSync().where((file) {
        return file.path.contains('mahakka_update_') && file.path.endsWith('.apk') && file.path.contains(latestVersion);
      }).toList();

      return apkFiles.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _showUpdateSnackBar(BuildContext context, String updateAvailableText, String updateNowText, String updateButton) {
    final snackBar = SnackBar(
      duration: const Duration(days: 365), // Permanent until dismissed
      content: Row(
        children: [
          Icon(Icons.system_update_rounded, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  updateAvailableText,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(updateNowText, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              _showUpdateDialog(context, startFromInstallation: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(updateButton, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      backgroundColor: Colors.orange[600],
      behavior: SnackBarBehavior.floating,
      elevation: 8.0,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.all(12),
      dismissDirection: DismissDirection.none,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showInstallationSnackBar(
    BuildContext context,
    String installReadyText,
    String installNowText,
    String installButton,
    String latestVersion,
  ) {
    final snackBar = SnackBar(
      duration: const Duration(days: 365), // Permanent until dismissed
      content: Row(
        children: [
          Icon(Icons.download_done_rounded, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  installReadyText,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(installNowText, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                SizedBox(height: 2),
                Text('v$latestVersion', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
              ],
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              _showUpdateDialog(context, startFromInstallation: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(installButton, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
      backgroundColor: Colors.green[600],
      behavior: SnackBarBehavior.floating,
      elevation: 8.0,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.all(12),
      dismissDirection: DismissDirection.none,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showUpdateDialog(BuildContext context, {bool startFromInstallation = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(startFromInstallation: startFromInstallation),
    );
  }
}
