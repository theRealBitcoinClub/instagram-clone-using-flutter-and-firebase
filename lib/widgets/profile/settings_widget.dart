import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/bch/mnemonic_backup_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';

import '../../provider/navigation_providers.dart';
import '../../provider/profile_providers.dart';
import '../../provider/user_provider.dart';
import '../../repositories/creator_repository.dart';
import '../../resources/auth_method.dart';
import 'header/settings_input_widget.dart';
import 'header/settings_option_widget.dart';

class SettingsWidget extends ConsumerStatefulWidget {
  final MemoModelCreator creator;
  final MemoModelUser? loggedInUser;
  final bool allowLogout;

  const SettingsWidget({Key? key, required this.creator, required this.loggedInUser, required this.allowLogout}) : super(key: key);

  @override
  ConsumerState<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends ConsumerState<SettingsWidget> {
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();
  bool isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _profileNameCtrl.text = widget.creator.name;
    _profileTextCtrl.text = widget.creator.profileText;
    _imgurCtrl.text = widget.creator.profileImgurUrl ?? "";
  }

  @override
  void dispose() {
    _profileNameCtrl.dispose();
    _profileTextCtrl.dispose();
    _imgurCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _buildSettingsDialog(theme);
  }

  Widget _buildSettingsDialog(ThemeData theme) {
    return SimpleDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      contentPadding: const EdgeInsets.only(bottom: 8.0),
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: _buildDialogTitle(theme),
      children: _buildDialogContent(theme),
    );
  }

  Widget _buildDialogTitle(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.settings_outlined, color: theme.dialogTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface),
        const SizedBox(width: 12),
        Expanded(child: Text("PROFILE SETTINGS", style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge)),
        IconButton(
          icon: Icon(Icons.close, color: theme.dialogTheme.titleTextStyle?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: "Close",
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  List<Widget> _buildDialogContent(ThemeData theme) {
    return [
      SettingsInputWidget(theme: theme, icon: Icons.badge_outlined, hintText: "Name", type: TextInputType.text, controller: _profileNameCtrl),
      SettingsInputWidget(
        theme: theme,
        icon: Icons.notes_outlined,
        hintText: "Bio/Text",
        type: TextInputType.multiline,
        controller: _profileTextCtrl,
        maxLines: 3,
      ),
      SettingsInputWidget(
        theme: theme,
        icon: Icons.image_outlined,
        hintText: "e.g. https://imgur.com/X32JJS",
        type: TextInputType.url,
        controller: _imgurCtrl,
      ),
      _buildSaveButton(theme),
      if (isSavingProfile) const LinearProgressIndicator(),
      Divider(color: theme.dividerColor.withOpacity(0.5), height: 20, thickness: 0.5, indent: 20, endIndent: 20),
      SettingsOptionWidget(
        theme: theme,
        icon: Icons.copy_all_outlined,
        text: "BACKUP MNEMONIC",
        dialogContext: context,
        onSelect: _showMnemonicBackupDialog,
      ),
      SettingsOptionWidget(
        theme: theme,
        icon: Icons.logout_rounded,
        text: "LOGOUT",
        dialogContext: context,
        onSelect: _logout,
        isDestructive: true,
        isEnabled: widget.allowLogout,
      ),
    ];
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24).copyWith(top: 20),
      child: ElevatedButton(
        onPressed: isSavingProfile ? null : _onSavePressed,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
        child: const Text("SAVE CHANGES"),
      ),
    );
  }

  void _onSavePressed() {
    _saveProfile(() => Navigator.of(context).pop(), () => showSnackBar("Failed to save profile.", context));
  }

  void _saveProfile(Function onSuccess, Function onFail) async {
    setState(() => isSavingProfile = true);

    try {
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final user = ref.read(userProvider);
      if (user == null) {
        onFail();
        return;
      }

      final newName = _profileNameCtrl.text.trim();
      final newText = _profileTextCtrl.text.trim();
      final newImgurUrl = _imgurCtrl.text.trim();

      final updates = <String, Future<dynamic>>{};
      bool changesMade = false;

      if (newName.isNotEmpty && newName != widget.creator.name) {
        updates['name'] = creatorRepo.profileSetName(newName, user);
        changesMade = true;
      }
      if (newText != widget.creator.profileText) {
        updates['text'] = creatorRepo.profileSetText(newText, user);
        changesMade = true;
      }
      if (newImgurUrl.isNotEmpty && newImgurUrl != widget.creator.profileImgurUrl) {
        updates['avatar'] = creatorRepo.profileSetAvatar(newImgurUrl, user);
        changesMade = true;
      }

      if (!changesMade) {
        showSnackBar("No changes to save. 🤔", context);
        onFail();
        return;
      }

      final results = await Future.wait(
        updates.entries.map((entry) async {
          final result = await entry.value;
          return MapEntry(entry.key, result);
        }),
      );

      final failedUpdates = results.where((e) => e.value != "success").map((e) => '${e.key}: ${e.value}').toList();

      if (failedUpdates.isNotEmpty) {
        final failMessage = failedUpdates.join(', ');
        showSnackBar("Update failed for: $failMessage", context);
        onFail();
      } else {
        showSnackBar("Profile updated successfully! ✨", context);
        MemoConfetti().launch(context);
        ref.refresh(profileCreatorStateProvider);
        onSuccess();
      }
    } catch (e) {
      showSnackBar("Profile update failed: $e", context);
      onFail();
    } finally {
      setState(() => isSavingProfile = false);
    }
  }

  void _showMnemonicBackupDialog() {
    if (widget.loggedInUser != null) {
      showDialog(
        context: context,
        builder: (ctx) => MnemonicBackupWidget(
          mnemonic: widget.loggedInUser!.mnemonic,
          onVerificationComplete: () {
            // This callback can be used to update the parent widget if needed
          },
        ),
      );
    }
  }

  void _logout() {
    ref.read(authCheckerProvider).logOut();
    ref.read(profileTargetIdProvider.notifier).state = null;
    ref.read(tabIndexProvider.notifier).setTab(0);
  }
}
