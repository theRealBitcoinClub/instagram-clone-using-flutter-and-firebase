import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart'; // Adjust path
import 'package:mahakka/memo/model/memo_model_post.dart'; // Adjust path
import 'package:mahakka/memo/model/memo_model_user.dart'; // Adjust path
import 'package:mahakka/utils/snackbar.dart'; // Adjust path
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart'; // Adjust path
import 'package:mahakka/widgets/textfield_input.dart'; // Adjust path

// Helper for logging errors consistently
void _logDialogError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileDialogHelpers - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

// --- Show Image Detail Dialog ---
void showCreatorImageDetail(
  BuildContext context,
  ThemeData theme,
  MemoModelCreator creator,
  bool Function() getShowDefaultAvatar, // Getter for state
  Function(bool) setShowDefaultAvatar, // Setter for state
) async {
  // Assuming refreshDetailScraper is a method on MemoModelCreator
  // This logic seems specific to the creator model, so it can stay here or be part of the creator model.
  await creator.refreshImageDetail();

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) {
        // Use StatefulBuilder if the dialog content needs to rebuild based on showDefaultAvatar
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return SimpleDialog(
              contentPadding: const EdgeInsets.all(10),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              children: [
                CircleAvatar(
                  radius: 130, // Responsive radius could be better
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: getShowDefaultAvatar() || creator.profileImageDetail().isEmpty
                      ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                      : NetworkImage(creator.profileImageDetail()),
                  onBackgroundImageError: getShowDefaultAvatar()
                      ? null
                      : (exception, stackTrace) {
                          _logDialogError("Error loading profile image detail in dialog", exception, stackTrace);
                          // Use the passed setter to update parent state
                          if (context.mounted) {
                            // Check original context
                            setShowDefaultAvatar(true);
                            // Also update the dialog's local state if necessary for immediate reflection
                            setDialogState(() {});
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- Show Post Dialog (for image grid tap) ---
void showPostDialog({
  required BuildContext context,
  required ThemeData theme,
  required MemoModelPost post,
  required MemoModelCreator? creator, // Pass the displayed creator
  required Widget imageWidget,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return SimpleDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceVariant,
              backgroundImage: creator?.profileImageAvatar().isEmpty ?? true
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creator!.profileImageAvatar()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                creator?.name ?? post.creatorId,
                style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: imageWidget, // The image widget passed from the grid
          ),
          if (post.text != null && post.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(post.text!, style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium),
            ),
        ],
      );
    },
  );
}

// --- BCH QR Code Dialog ---
void showBchQRDialog({
  required BuildContext context,
  required ThemeData theme,
  required MemoModelUser user,
  required bool Function() getTempToggleState, // Getter for the toggle state
  required Function(bool) setTempToggleState, // Setter for the toggle state
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      // QrCodeDialog should ideally manage its own internal toggle state
      // or use a StatefulBuilder if it needs to rebuild when the toggle changes.
      return QrCodeDialog(
        // Assuming QrCodeDialog is already themed or adapts
        user: user,
        initialToggleState: getTempToggleState(),
        onToggle: (newState) {
          // This callback updates the state in _ProfileScreenWidgetState
          setTempToggleState(newState);
          // If QrCodeDialog itself needs to rebuild, it should use its own setState or StatefulBuilder
        },
      );
    },
  );
}

// --- Profile Settings Dialog ---
void showProfileSettingsDialog({
  required BuildContext context,
  required ThemeData theme,
  required MemoModelCreator creator,
  required MemoModelUser? loggedInUser, // For mnemonic and logout
  required TextEditingController profileNameCtrl,
  required TextEditingController profileTextCtrl,
  required TextEditingController imgurCtrl,
  required VoidCallback onSave, // Callback to _ProfileScreenWidgetState._saveProfile
  required VoidCallback onLogout,
  required VoidCallback onBackupMnemonic,
}) {
  // Initialize controllers with current creator data
  profileNameCtrl.text = creator.name;
  profileTextCtrl.text = creator.profileText;
  imgurCtrl.text = creator.profileImageAvatar(); // Or a specific field for avatar URL input

  showDialog(
    context: context,
    barrierDismissible: true, // Allow dismissing by tapping outside
    builder: (dialogCtx) {
      return SimpleDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.only(bottom: 8.0), // Reduced bottom padding
        backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.settings_outlined, color: theme.dialogTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(child: Text("PROFILE SETTINGS", style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge)),
            IconButton(
              icon: Icon(Icons.close, color: theme.dialogTheme.titleTextStyle?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              tooltip: "Close",
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        children: [
          _buildSettingsInput(theme, Icons.badge_outlined, "Display Name", TextInputType.text, profileNameCtrl),
          _buildSettingsInput(theme, Icons.notes_outlined, "Profile Bio/Text", TextInputType.multiline, profileTextCtrl, maxLines: 3),
          _buildSettingsInput(theme, Icons.image_outlined, "Avatar Image URL (e.g. Imgur)", TextInputType.url, imgurCtrl),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24).copyWith(top: 20),
            child: ElevatedButton(
              onPressed: () {
                onSave(); // Call the save callback passed from _ProfileScreenWidgetState
                Navigator.of(dialogCtx).pop(); // Close dialog after initiating save
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44), // Full width button
              ),
              child: const Text("SAVE CHANGES"),
            ),
          ),
          Divider(color: theme.dividerColor.withOpacity(0.5), height: 20, thickness: 0.5, indent: 20, endIndent: 20),
          _buildSettingsOption(theme, Icons.copy_all_outlined, "BACKUP MNEMONIC", dialogCtx, onBackupMnemonic),
          _buildSettingsOption(theme, Icons.logout_rounded, "LOGOUT", dialogCtx, onLogout, isDestructive: true),
        ],
      );
    },
  );
}

Widget _buildSettingsInput(
  ThemeData theme,
  IconData icon,
  String hintText,
  TextInputType type,
  TextEditingController ctrl, {
  int maxLines = 1,
}) {
  return Padding(
    // Changed from SimpleDialogOption for better layout control
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      crossAxisAlignment: type == TextInputType.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: type == TextInputType.multiline ? 8.0 : 0.0), // Adjust icon for multiline
          child: Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextInputField(
            // Assuming TextInputField is themed
            hintText: hintText,
            textEditingController: ctrl,
            textInputType: type,
            // maxLines: maxLines, // Use passed maxLines
            // Add any other necessary properties for TextInputField
          ),
        ),
      ],
    ),
  );
}

Widget _buildSettingsOption(
  ThemeData theme,
  IconData icon,
  String text,
  BuildContext dialogCtx, // Keep for Navigator.pop
  VoidCallback onSelect, {
  bool isDestructive = false,
}) {
  final color = isDestructive ? theme.colorScheme.error : (theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface);

  return SimpleDialogOption(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    onPressed: () {
      Navigator.of(dialogCtx).pop(); // Close dialog first
      onSelect(); // Then execute action
    },
    child: Row(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 20),
        const SizedBox(width: 16),
        Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
      ],
    ),
  );
}

// --- Utility: Copy to Clipboard ---
Future<void> copyToClipboard(String text, String successMessage, BuildContext context) async {
  if (text.isEmpty) {
    if (context.mounted) showSnackBar("Nothing to copy.", context);
    return;
  }
  try {
    await FlutterClipboard.copy(text);
    if (context.mounted) showSnackBar(successMessage, context);
  } catch (e) {
    _logDialogError("Copy to clipboard failed", e);
    if (context.mounted) showSnackBar('Copy failed: $e', context);
  }
}
