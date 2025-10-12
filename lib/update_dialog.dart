import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/update_service.dart';
import 'package:path_provider/path_provider.dart';

import '../provider/translation_service.dart';

class UpdateDialog extends ConsumerStatefulWidget {
  final bool startFromInstallation;

  const UpdateDialog({Key? key, this.startFromInstallation = false}) : super(key: key);

  @override
  _UpdateDialogState createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  bool _isVerifying = false;
  bool _showManualCheck = false;
  bool _hasError = false;
  double _downloadProgress = 0.0;
  final TextEditingController _sha256Controller = TextEditingController();
  String _verificationResult = '';

  // Private properties for all strings initialized with original text
  String _updateTitle = 'Update Available';
  String _updateMessage = 'A new version is available. Would you like to update now?';
  String _laterText = 'Later';
  String _updateNowText = 'Update Now';
  String _downloadingText = 'Downloading...';
  String _verifyingText = 'Verifying Security...';
  String _securityVerifiedText = 'Security verified with SHA256';
  String _securityCheckFailedText = 'Security check failed';
  String _manualCheckText = 'SHA256 Check';
  String _enterSha256Text = 'Enter SHA256 from trusted source';
  String _verifyText = 'Verify';
  String _automatedCheckText = 'Automated security check passed';
  String _manualCheckVerifiedText = 'Manual verification successful';
  String _manualCheckFailedText = 'Manual verification failed';
  String _currentVersionText = 'Current version';
  String _latestVersionText = 'Latest version';
  String _noChecksumText = 'No automated checksum available';
  String _noApkFoundText = 'No downloaded APK found';
  String _installNowText = 'Install Now';
  String _tryManualCheckText = 'Try Manual Check';

  @override
  void initState() {
    super.initState();
    // If we're starting from installation, check for existing APK and proceed
    if (widget.startFromInstallation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForExistingApkAndInstall();
      });
    }
  }

  Future<void> _checkForExistingApkAndInstall() async {
    final tempDir = await getTemporaryDirectory();
    final updateInfo = ref.read(updateInfoProvider);

    final apkFiles = Directory(tempDir.path).listSync().where((file) {
      return file.path.contains('mahakka_update_') && file.path.endsWith('.apk') && file.path.contains(updateInfo.latestVersion);
    }).toList();

    if (apkFiles.isNotEmpty) {
      final latestApk = File(apkFiles.last.path);
      setState(() {
        _verificationResult = 'Found downloaded APK. Ready to install.';
      });

      // Auto-proceed to installation after a brief delay
      await Future.delayed(Duration(milliseconds: 500));
      _proceedWithInstallation();
    } else {
      setState(() {
        _verificationResult = 'No downloaded APK found. Please download again.';
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _sha256Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final theme = Theme.of(context);
    final updateInfo = ref.watch(updateInfoProvider);

    // Initialize translations in build method since it's reactive
    _initializeTranslations(ref);

    var isErrorState = _verificationResult.contains('failed') || _hasError;
    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.system_update_rounded, color: theme.colorScheme.primary),
          SizedBox(width: 12),
          Text(_updateTitle, style: theme.textTheme.titleLarge),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isDownloading && !_isVerifying && !_showManualCheck)
            // if (!_isDownloading && !_isVerifying)
            Text(
              '$_updateMessage\n\n$_currentVersionText: ${updateInfo.currentVersion}\n$_latestVersionText: ${updateInfo.latestVersion}',
              style: theme.textTheme.bodyMedium,
            ),

          if (_isDownloading)
            Column(
              children: [
                Text(_downloadingText, style: theme.textTheme.bodyMedium),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 8),
                Text('${(_downloadProgress * 100).toStringAsFixed(1)}%', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),

          if (_isVerifying)
            Column(
              children: [
                Text(_verifyingText, style: theme.textTheme.bodyMedium),
                SizedBox(height: 16),
                CircularProgressIndicator(color: theme.colorScheme.primary),
              ],
            ),

          if (_verificationResult.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isErrorState ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isErrorState ? Colors.red : Colors.green),
              ),
              child: Row(
                children: [
                  Icon(isErrorState ? Icons.error_outline : Icons.check_circle, color: isErrorState ? Colors.red : Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(_verificationResult, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
                  ),
                ],
              ),
            ),

          if (_showManualCheck)
            // if (false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                Text(_enterSha256Text, style: theme.textTheme.bodyMedium),
                SizedBox(height: 12),
                TextField(
                  controller: _sha256Controller,
                  decoration: InputDecoration(
                    hintText: 'a1b2c3d4e5f6...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: TextStyle(fontFamily: 'Monospace'),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _performManualVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: Text(_verifyText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
      actions: [
        if (_verificationResult.isEmpty && !_isDownloading && !_isVerifying && !_showManualCheck) ...[
          // if (_verificationResult.isEmpty && !_isDownloading && !_isVerifying) ...[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(_laterText, style: TextStyle(color: theme.colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: _startUpdate,
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary),
            child: Text(_updateNowText),
          ),
        ],

        // if (_isDownloading || _isVerifying)
        //   TextButton(
        //     onPressed: null,
        //     child: Text(
        //       _isDownloading ? _downloadingText : _verifyingText,
        //       style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        //     ),
        //   ),
        if (_verificationResult.isNotEmpty && !_verificationResult.contains('failed') && !_showManualCheck)
          // if (_verificationResult.isNotEmpty && !_verificationResult.contains('failed'))
          Row(
            children: [
              // TextButton(
              //   onPressed: () {
              //     setState(() {
              //       _showManualCheck = true;
              //       _verificationResult = '';
              //     });
              //   },
              //   child: Text(_manualCheckText),
              // ),
              // SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _proceedWithInstallation,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: Text(_installNowText),
                ),
              ),
            ],
          ),

        if (_verificationResult.contains('failed') && !_showManualCheck)
          // if (true)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showManualCheck = true;
                _verificationResult = '';
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: Text(_tryManualCheckText),
          ),
      ],
    );
  }

  void _initializeTranslations(WidgetRef ref) {
    _updateTitle = ref.watch(autoTranslationTextProvider(_updateTitle)).value ?? _updateTitle;
    _updateMessage = ref.watch(autoTranslationTextProvider(_updateMessage)).value ?? _updateMessage;
    _laterText = ref.watch(autoTranslationTextProvider(_laterText)).value ?? _laterText;
    _updateNowText = ref.watch(autoTranslationTextProvider(_updateNowText)).value ?? _updateNowText;
    _downloadingText = ref.watch(autoTranslationTextProvider(_downloadingText)).value ?? _downloadingText;
    _verifyingText = ref.watch(autoTranslationTextProvider(_verifyingText)).value ?? _verifyingText;
    _securityVerifiedText = ref.watch(autoTranslationTextProvider(_securityVerifiedText)).value ?? _securityVerifiedText;
    _securityCheckFailedText = ref.watch(autoTranslationTextProvider(_securityCheckFailedText)).value ?? _securityCheckFailedText;
    _manualCheckText = ref.watch(autoTranslationTextProvider(_manualCheckText)).value ?? _manualCheckText;
    _enterSha256Text = ref.watch(autoTranslationTextProvider(_enterSha256Text)).value ?? _enterSha256Text;
    _verifyText = ref.watch(autoTranslationTextProvider(_verifyText)).value ?? _verifyText;
    _automatedCheckText = ref.watch(autoTranslationTextProvider(_automatedCheckText)).value ?? _automatedCheckText;
    _manualCheckVerifiedText = ref.watch(autoTranslationTextProvider(_manualCheckVerifiedText)).value ?? _manualCheckVerifiedText;
    _manualCheckFailedText = ref.watch(autoTranslationTextProvider(_manualCheckFailedText)).value ?? _manualCheckFailedText;
    _currentVersionText = ref.watch(autoTranslationTextProvider(_currentVersionText)).value ?? _currentVersionText;
    _latestVersionText = ref.watch(autoTranslationTextProvider(_latestVersionText)).value ?? _latestVersionText;
    _noChecksumText = ref.watch(autoTranslationTextProvider(_noChecksumText)).value ?? _noChecksumText;
    _noApkFoundText = ref.watch(autoTranslationTextProvider(_noApkFoundText)).value ?? _noApkFoundText;
    _installNowText = ref.watch(autoTranslationTextProvider(_installNowText)).value ?? _installNowText;
    _tryManualCheckText = ref.watch(autoTranslationTextProvider(_tryManualCheckText)).value ?? _tryManualCheckText;
  }

  void _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _verificationResult = '';
      _hasError = false;
    });

    final updateService = ref.read(updateServiceProvider);
    final updateInfo = ref.read(updateInfoProvider);

    await updateService.downloadAndInstallApk(
      latestVersion: updateInfo.latestVersion,
      onProgress: (bytes, total) {
        setState(() {
          _downloadProgress = bytes / total;
        });
      },
      onComplete: () {
        setState(() {
          _isDownloading = false;
          _isVerifying = true;
        });

        // Simulate verification delay
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _isVerifying = false;
            if (updateInfo.expectedSha256 != null) {
              _verificationResult = _automatedCheckText;
            } else {
              _verificationResult = _noChecksumText;
              _showManualCheck = true;
            }
          });
        });
      },
      onError: (error) {
        setState(() {
          _isDownloading = false;
          _isVerifying = false;
          _verificationResult = error;
          _hasError = true;
        });
      },
      expectedSha256: updateInfo.expectedSha256,
    );
  }

  void _performManualVerification() async {
    if (_sha256Controller.text.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _verificationResult = '';
      _showManualCheck = false;
    });

    final updateService = ref.read(updateServiceProvider);
    final tempDir = await getTemporaryDirectory();
    final apkFiles = Directory(tempDir.path).listSync().where((file) {
      return file.path.contains('mahakka_update_') && file.path.endsWith('.apk');
    }).toList();

    if (apkFiles.isNotEmpty) {
      final latestApk = File(apkFiles.last.path);
      final isValid = updateService.verifyManualSha256(latestApk, _sha256Controller.text);

      setState(() {
        _isVerifying = false;
        _verificationResult = isValid ? _manualCheckVerifiedText : _manualCheckFailedText;
      });
    } else {
      setState(() {
        _isVerifying = false;
        _verificationResult = _noApkFoundText;
      });
    }
  }

  void _proceedWithInstallation() async {
    final updateService = ref.read(updateServiceProvider);
    final tempDir = await getTemporaryDirectory();
    final apkFiles = Directory(tempDir.path).listSync().where((file) {
      return file.path.contains('mahakka_update_') && file.path.endsWith('.apk');
    }).toList();

    if (apkFiles.isNotEmpty) {
      final latestApk = File(apkFiles.last.path);
      try {
        await updateService.installApk(latestApk, context);
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _verificationResult = 'Installation failed: $e';
        });
      }
    }
  }
}
