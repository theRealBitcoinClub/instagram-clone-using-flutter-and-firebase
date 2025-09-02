import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';

import '../../utils/snackbar.dart';

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
  bool Function() getShowDefaultAvatar,
  Function(bool) setShowDefaultAvatar,
) async {
  await creator.refreshImageDetail();

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return SimpleDialog(
              contentPadding: const EdgeInsets.all(10),
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              children: [
                CircleAvatar(
                  radius: 130,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: getShowDefaultAvatar() || creator.profileImageDetail().isEmpty
                      ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                      : NetworkImage(creator.profileImageDetail()),
                  onBackgroundImageError: getShowDefaultAvatar()
                      ? null
                      : (exception, stackTrace) {
                          _logDialogError("Error loading profile image detail in dialog", exception, stackTrace);
                          if (context.mounted) {
                            setShowDefaultAvatar(true);
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
  required MemoModelCreator? creator,
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
          Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: imageWidget),
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
void showQrCodeDialog({
  required BuildContext context,
  required ThemeData theme,
  MemoModelUser? user,
  MemoModelCreator? creator,
  required bool Function() getTempToggleState,
  required Function(bool) setTempToggleState,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return QrCodeDialog(
        cashtokenAddress: user != null
            ? user.bchAddressCashtokenAware
            : creator!.hasRegisteredAsUser
            ? creator.bchAddressCashtokenAware
            : null,
        legacyAddress: user != null
            ? user.legacyAddressMemoBch
            : creator!.hasRegisteredAsUser
            ? creator.id
            : creator.id,
        initialToggleState: getTempToggleState(),
        onToggle: (newState) {
          setTempToggleState(newState);
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
  required MemoModelUser? loggedInUser,
  required TextEditingController profileNameCtrl,
  required TextEditingController profileTextCtrl,
  required TextEditingController imgurCtrl,
  required onSaveProfileSettings,
  required VoidCallback onLogout,
  required VoidCallback onBackupMnemonic,
  required bool isLogoutEnabled,
  required bool isSavingProfile, // New parameter
}) {
  profileNameCtrl.text = creator.name;
  profileTextCtrl.text = creator.profileText;
  imgurCtrl.text = creator.profileImgurUrl ?? "";

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) {
      return SimpleDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.only(bottom: 8.0),
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
          _buildSettingsInput(theme, Icons.badge_outlined, "Name", TextInputType.text, profileNameCtrl),
          _buildSettingsInput(theme, Icons.notes_outlined, "Bio/Text", TextInputType.multiline, profileTextCtrl, maxLines: 3),
          _buildSettingsInput(theme, Icons.image_outlined, "e.g. https://imgur.com/X32JJS", TextInputType.url, imgurCtrl),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24).copyWith(top: 20),
            child: ElevatedButton(
              onPressed: () {
                if (!isSavingProfile) {
                  onSaveProfileSettings(
                    () {
                      Navigator.of(dialogCtx).pop();
                    },
                    () {
                      //TODO print("failed for some or all fields, mark these in red?");
                      showSnackBar("Failed to save profile.", dialogCtx);
                    },
                  );
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              child: const Text("SAVE CHANGES"),
            ),
          ),
          isSavingProfile ? LinearProgressIndicator() : SizedBox(),
          Divider(color: theme.dividerColor.withOpacity(0.5), height: 20, thickness: 0.5, indent: 20, endIndent: 20),
          _buildSettingsOption(theme, Icons.copy_all_outlined, "BACKUP MNEMONIC", dialogCtx, onBackupMnemonic),
          // Pass isLogoutEnabled to the logout option
          _buildSettingsOption(theme, Icons.logout_rounded, "LOGOUT", dialogCtx, onLogout, isDestructive: true, isEnabled: isLogoutEnabled),
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
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      crossAxisAlignment: type == TextInputType.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: type == TextInputType.multiline ? 8.0 : 0.0),
          child: Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            ),
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
  BuildContext dialogCtx,
  VoidCallback onSelect, {
  bool isDestructive = false,
  bool isEnabled = true, // New parameter to control state
}) {
  final baseColor = isDestructive ? theme.colorScheme.error : (theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface);
  // Adjust color and onPressed based on isEnabled
  final color = isEnabled ? baseColor : baseColor.withOpacity(0.4);
  final onPressedCallback = isEnabled
      ? () {
          Navigator.of(dialogCtx).pop();
          onSelect();
        }
      : () => showSnackBar("You haz to backup your mnemonic first.", dialogCtx);

  return SimpleDialogOption(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    onPressed: onPressedCallback,
    child: Row(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 20),
        const SizedBox(width: 16),
        Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
      ],
    ),
  );
}
