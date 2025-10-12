// lib/widgets/update_monitor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/update_dialog.dart';
import 'package:mahakka/update_service.dart';

class UpdateMonitor extends ConsumerStatefulWidget {
  const UpdateMonitor({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdateMonitor> createState() => _UpdateMonitorState();
}

class _UpdateMonitorState extends ConsumerState<UpdateMonitor> {
  String _updateAvailableText = 'Update Available';
  String _updateNowText = 'Tap here';
  String _updateButton = 'UPDATE';

  @override
  Widget build(BuildContext context) {
    ref.watch(updateCheckProvider);
    final updateInfo = ref.watch(updateInfoProvider);
    final updateService = ref.read(updateServiceProvider);
    _updateAvailableText = _getTranslation(_updateAvailableText);
    _updateNowText = _getTranslation(_updateNowText);
    _updateButton = _getTranslation(_updateButton);

    // Check if we should show update snackbar
    if (updateInfo.updateAvailable && updateService.shouldShowReminder(updateInfo)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUpdateSnackBar(context, updateInfo);
      });
    }

    return const SizedBox.shrink();
  }

  String _getTranslation(String text) {
    return ref.watch(autoTranslationTextProvider(text)).value ?? text;
  }

  void _showUpdateSnackBar(BuildContext context, UpdateInfo updateInfo) {
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
                  _updateAvailableText,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(_updateNowText, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              _showUpdateDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(_updateButton, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(ref: ref),
    );
  }
}
