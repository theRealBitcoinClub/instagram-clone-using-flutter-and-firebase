import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/bch/mnemonic_backup_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/navigation_providers.dart';
import '../../provider/profile_providers.dart';
import '../../provider/user_provider.dart';
import '../../repositories/creator_repository.dart';
import '../../resources/auth_method.dart';
import 'header/settings_input_widget.dart';
import 'header/settings_option_widget.dart';

enum SettingsTab { creator, tips, user }

class SettingsWidget extends ConsumerStatefulWidget {
  final MemoModelUser loggedInUser;
  final SettingsTab initialTab;

  const SettingsWidget({Key? key, required this.initialTab, required this.loggedInUser}) : super(key: key);

  @override
  ConsumerState<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends ConsumerState<SettingsWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();
  bool isSavingProfile = false;
  TipReceiver? _selectedTipReceiver;
  TipAmount? _selectedTipAmount;
  bool allowLogout = false;
  String get key => 'mnemonic_backup_verified ${widget.loggedInUser.id}';
  late MemoModelCreator creator;

  late TabController _tabController;
  int _currentTabIndex = 0;

  List<Widget> tabs() {
    return const [
      Tab(icon: Icon(Icons.account_circle_outlined), text: 'Creator'),
      Tab(icon: Icon(Icons.currency_bitcoin_rounded), text: 'Tips'),
      Tab(icon: Icon(Icons.settings), text: 'User'),
    ];
  }

  @override
  void initState() {
    super.initState();
    creator = widget.loggedInUser.creator;
    _tabController = TabController(length: tabs().length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initializeControllers();
    _initAllowLogout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.index = widget.initialTab.index;
      // _tabController.animateTo(widget.initialTab.index);
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  void _initAllowLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        allowLogout = prefs.getBool(key) ?? false;
      });
    }
  }

  void _initializeControllers() {
    _profileNameCtrl.text = creator.name;
    _profileTextCtrl.text = creator.profileText;
    _imgurCtrl.text = creator.profileImgurUrl ?? "";

    _selectedTipReceiver = widget.loggedInUser.tipReceiver;
    _selectedTipAmount = widget.loggedInUser.tipAmountEnum;
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with tabs and close button
            _buildDialogHeader(theme),

            // Tab content with animation
            Expanded(
              child: TabBarView(controller: _tabController, children: [_buildGeneralTab(theme), _buildTipsTab(theme), _buildUserTab(theme)]),
            ),

            // Bottom buttons row (appears on all tabs)
            _buildBottomButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Tab selector
            Expanded(
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                unselectedLabelStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
                labelStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                indicator: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                ),
                tabs: tabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(child: _buildCloseButton(theme)),
          const SizedBox(width: 12),
          Expanded(child: _buildSaveButton(theme)),
        ],
      ),
    );
  }

  Widget _buildUserTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsOptionWidget(
            theme: theme,
            icon: Icons.copy_all_outlined,
            text: "BACKUP MNEMONIC",
            dialogContext: context,
            onSelect: _showMnemonicBackupDialog,
          ),
          const SizedBox(height: 8),
          SettingsOptionWidget(
            theme: theme,
            icon: Icons.logout_rounded,
            text: "LOGOUT",
            dialogContext: context,
            onSelect: _logout,
            isDestructive: true,
            isEnabled: allowLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          SettingsInputWidget(
            theme: theme,
            icon: Icons.badge_outlined,
            hintText: "Name",
            type: TextInputType.text,
            controller: _profileNameCtrl,
          ),
          const SizedBox(height: 0),
          SettingsInputWidget(
            theme: theme,
            icon: Icons.notes_outlined,
            hintText: "Bio/Text",
            type: TextInputType.multiline,
            controller: _profileTextCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 0),
          SettingsInputWidget(
            theme: theme,
            icon: Icons.image_outlined,
            hintText: "e.g. https://imgur.com/X32JJS",
            type: TextInputType.url,
            controller: _imgurCtrl,
          ),
          if (isSavingProfile) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTipsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tip Receiver Selection
          _buildTipReceiverDropdown(theme),
          const SizedBox(height: 20),

          // Tip Amount Selection
          _buildTipAmountDropdown(theme),
          if (isSavingProfile) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTipReceiverDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tip Receiver", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipReceiver>(
          value: _selectedTipReceiver,
          onChanged: (TipReceiver? newValue) {
            setState(() {
              _selectedTipReceiver = newValue;
            });
          },
          items: TipReceiver.values.map((TipReceiver receiver) {
            return DropdownMenuItem<TipReceiver>(value: receiver, child: Text(receiver.displayName));
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildTipAmountDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tip Amount", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipAmount>(
          value: _selectedTipAmount,
          onChanged: (TipAmount? newValue) {
            setState(() {
              _selectedTipAmount = newValue;
            });
          },
          items: TipAmount.values.map((TipAmount amount) {
            return DropdownMenuItem<TipAmount>(value: amount, child: Text(_getTipAmountDisplayName(amount)));
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: theme.colorScheme.outline),
        foregroundColor: theme.colorScheme.onSurface, // Uses theme's error color (often red)
      ),
      child: Text("CANCEL", style: TextStyle(color: theme.colorScheme.onSurface)),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: isSavingProfile ? null : _onSavePressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 44),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text("SAVE"),
    );
  }

  String _getTipAmountDisplayName(TipAmount amount) {
    final String name = amount.name[0].toUpperCase() + amount.name.substring(1);
    final formattedValue = amount.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return "$name ($formattedValue satoshis)";
  }

  void _onSavePressed() {
    _saveProfile(() => Navigator.of(context).pop(), () => showSnackBar(type: SnackbarType.error, "Failed to save profile.", context));
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

      // Profile updates
      if (newName.isNotEmpty && newName != creator.name) {
        updates['name'] = creatorRepo.profileSetName(newName, user);
        changesMade = true;
      }
      if (newText != creator.profileText) {
        updates['text'] = creatorRepo.profileSetText(newText, user);
        changesMade = true;
      }
      if (newImgurUrl.isNotEmpty && newImgurUrl != creator.profileImgurUrl) {
        updates['avatar'] = creatorRepo.profileSetAvatar(newImgurUrl, user);
        changesMade = true;
      }

      // Tip settings updates
      if (_selectedTipReceiver != null && _selectedTipReceiver != user.tipReceiver) {
        updates['tip_receiver'] = ref.read(userNotifierProvider.notifier).updateTipReceiver(_selectedTipReceiver!);
        changesMade = true;
      }

      if (_selectedTipAmount != null && _selectedTipAmount != user.tipAmountEnum) {
        updates['tip_amount'] = ref.read(userNotifierProvider.notifier).updateTipAmount(_selectedTipAmount!);
        changesMade = true;
      }

      if (!changesMade) {
        showSnackBar(type: SnackbarType.info, "No changes to save. 🤔", context);
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
        showSnackBar(type: SnackbarType.info, "Update failed for: $failMessage", context);
        onFail();
      } else {
        showSnackBar(type: SnackbarType.success, "Profile updated successfully! ✨", context);
        MemoConfetti().launch(context);

        // Refresh user data
        ref.invalidate(userProvider);
        ref.invalidate(profileCreatorStateProvider);

        onSuccess();
      }
    } catch (e) {
      showSnackBar(type: SnackbarType.error, "Profile update failed: $e", context);
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
          mnemonic: widget.loggedInUser.mnemonic,
          onVerificationComplete: () {
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool(key, true);
              if (mounted) {
                setState(() {
                  allowLogout = true;
                });
              }
            });
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
