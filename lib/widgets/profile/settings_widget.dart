// lib/widgets/profile/settings_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/bch/mnemonic_backup_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/navigation_providers.dart';
import '../../provider/profile_providers.dart';
import '../../provider/user_provider.dart';
import '../../repositories/creator_repository.dart';
import '../../resources/auth_method.dart';
import '../../tab_item_data.dart';
import 'header/settings_input_widget.dart';
import 'header/settings_option_widget.dart';

enum SettingsTab { creator, tips, user }

class SettingsWidget extends ConsumerStatefulWidget {
  final SettingsTab initialTab;

  const SettingsWidget({Key? key, required this.initialTab}) : super(key: key);

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
  late String _mnemonicBackupKey;
  bool _controllersInitialized = false;

  late TabController _tabController;
  int _currentTabIndex = 0;

  List<Widget> tabs() {
    return const [
      Tab(icon: Icon(Icons.account_circle_outlined), text: 'Creator'),
      Tab(icon: Icon(Icons.currency_bitcoin_rounded), text: 'Tips'),
      Tab(icon: Icon(Icons.settings), text: 'User'),
    ];
  }
  //
  // List<Widget> tabs({BoxDecoration? decoration}) {
  //   Widget buildTabContent(IconData icon, String text) {
  //     final content = Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon), SizedBox(width: 8), Text(text)]);
  //
  //     return decoration != null ? Container(decoration: decoration, child: content) : content;
  //   }
  //
  //   return [
  //     Tab(child: buildTabContent(Icons.account_circle_outlined, 'Creator')),
  //     Tab(child: buildTabContent(Icons.currency_bitcoin_rounded, 'Tips')),
  //     Tab(child: buildTabContent(Icons.settings, 'User')),
  //   ];
  // }
  //
  // Widget _buildReversedTab(String text, ThemeData theme) {
  //   return Tab(
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       decoration: BoxDecoration(
  //         color: theme.colorScheme.primary, // Unselected background
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Text(text),
  //     ),
  //   );
  // }
  //
  // List<Widget> tabs({BoxDecoration? decoration}) {
  //   return _buildTabsWithDecoration(decoration);
  // }
  //
  // List<Widget> _buildTabsWithDecoration(BoxDecoration? decoration) {
  //   final tabData = [
  //     {'icon': Icons.account_circle_outlined, 'text': 'Creator'},
  //     {'icon': Icons.currency_bitcoin_rounded, 'text': 'Tips'},
  //     {'icon': Icons.settings, 'text': 'User'},
  //   ];
  //
  //   return tabData.map((data) {
  //     final widget = Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [Icon(data['icon'] as IconData), SizedBox(width: 8), Text(data['text'] as String)],
  //     );
  //
  //     return Tab(
  //       child: decoration != null ? Container(decoration: decoration, child: widget) : widget,
  //     );
  //   }).toList();
  // }
  // List<Widget> tabs({BoxDecoration? decoration}) {
  //   return [
  //     Tab(
  //       child: Container(
  //         decoration: decoration,
  //         child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_circle_outlined), SizedBox(width: 8), Text('Creator')]),
  //       ),
  //     ),
  //     Tab(
  //       child: Container(
  //         decoration: decoration,
  //         child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.currency_bitcoin_rounded), SizedBox(width: 8), Text('Tips')]),
  //       ),
  //     ),
  //     Tab(
  //       child: Container(
  //         decoration: decoration,
  //         child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.settings), SizedBox(width: 8), Text('User')]),
  //       ),
  //     ),
  //   ];
  // }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: tabs().length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initAllowLogout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController.index = widget.initialTab.index;
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
        allowLogout = prefs.getBool(_mnemonicBackupKey) ?? false;
      });
    }
  }

  void _initializeControllers(MemoModelCreator creator, MemoModelUser user) {
    if (_controllersInitialized) return;

    _profileNameCtrl.text = creator.name;
    _profileTextCtrl.text = creator.profileText;
    _imgurCtrl.text = creator.profileImgurUrl ?? "";
    _selectedTipReceiver = user.tipReceiver;
    _selectedTipAmount = user.tipAmountEnum;

    _controllersInitialized = true;
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

    // Watch user provider - always non-null as per your requirement
    final user = ref.watch(userProvider)!;
    _mnemonicBackupKey = 'mnemonic_backup_verified${user.id}';

    // Watch creator repository and wait for non-null value
    // final creatorAsync = ref.watch(creatorRepositoryProvider
    //     .select((repo) => repo.getCreator(user.id, scrapeIfNotFound: true, useCache: true)));
    final creatorAsync = ref.watch(profileDataProvider);
    // final creatorAsync = ref.watch(settingsCreatorProvider(user.id));

    // Show loading until creator is available
    return creatorAsync.when(
      loading: () => _buildLoadingWidget(theme),
      error: (error, stack) => _buildErrorWidget(theme, "Failed to load creator: $error"),
      data: (profileData) {
        // final actualCreator = creator ?? user.creator;

        // Initialize controllers once when creator is available
        if (!_controllersInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _initializeControllers(profileData.creator!, user);
              });
            }
          });
        }

        return _buildSettingsDialog(theme, profileData.creator!, user);
      },
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 450),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String error) {
    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 450),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(error, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsDialog(ThemeData theme, MemoModelCreator creator, MemoModelUser user) {
    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHeader(theme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildGeneralTab(theme), _buildTipsTab(theme), _buildUserTab(theme, user)],
              ),
            ),
            _buildBottomButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(ThemeData theme) {
    return Container(
      // decoration: BoxDecoration(
      //   border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
      // ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                dividerHeight: 1,
                dividerColor: theme.dividerColor.withAlpha(122),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: theme.colorScheme.primary, // White text on colored background
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                unselectedLabelStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
                labelStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                indicator: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(12), // Selected tab background color
                  // borderRadius: BorderRadius.circular(8),
                  // border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
                ),
                indicatorPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                tabs: tabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  //
  // Expanded(
  // child: TabBar(
  // controller: _tabController,
  // indicatorSize: TabBarIndicatorSize.tab,
  // labelColor: theme.colorScheme.primary,
  // unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
  // unselectedLabelStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400),
  // labelStyle: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  // indicator: BoxDecoration(
  // border: Border(bottom: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
  // ),
  // tabs: tabs(),
  // ),
  // ),

  Widget _buildBottomButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      // decoration: BoxDecoration(
      //   border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
      // ),
      child: Row(
        children: [
          Expanded(child: _buildCloseButton(theme)),
          const SizedBox(width: 12),
          Expanded(child: _buildSaveButton(theme)),
        ],
      ),
    );
  }

  Widget _buildUserTab(ThemeData theme, MemoModelUser user) {
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
          const SizedBox(height: 8),
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
          _buildTipReceiverDropdown(theme),
          const SizedBox(height: 20),
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
        foregroundColor: theme.colorScheme.onSurface,
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
    _saveProfile(() => Navigator.of(context).pop(), () {});
  }

  void _saveProfile(Function onSuccess, Function onFail) async {
    setState(() => isSavingProfile = true);

    try {
      final user = ref.read(userProvider)!;
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final userNotifier = ref.read(userNotifierProvider.notifier);
      // final creatorAsync = ref.read(creatorRepositoryProvider
      //     .select((repo) => repo.getCreator(user.id, scrapeIfNotFound: true, useCache: true)));
      // final creatorAsync = ref.read(settingsCreatorProvider(user.id));
      final creatorAsync = ref.read(profileDataProvider);

      MemoModelCreator creator = creatorAsync.value!.creator!; // ?? user.creator;

      final newName = _profileNameCtrl.text.trim();
      final newText = _profileTextCtrl.text.trim();
      final newImgurUrl = _imgurCtrl.text.trim();

      var hasChangedImgur = newImgurUrl.isNotEmpty && newImgurUrl != creator.profileImgurUrl;
      final bool hasTextInputChanges = (newName.isNotEmpty && newName != creator.name) || (newText != creator.profileText) || (hasChangedImgur);

      final bool hasTipChanges =
          (_selectedTipReceiver != null && _selectedTipReceiver != user.tipReceiver) ||
          (_selectedTipAmount != null && _selectedTipAmount != user.tipAmountEnum);

      if (!hasTextInputChanges && !hasTipChanges) {
        showSnackBar(type: SnackbarType.info, "No changes to save. 🤔", context);
        return;
      }

      final results = await Future.wait([
        if (hasTextInputChanges)
          creatorRepo.updateProfile(
            creator: creator,
            name: newName.isNotEmpty && newName != creator.name ? newName : null,
            text: newText != creator.profileText ? newText : null,
            avatar: hasChangedImgur ? newImgurUrl : null,
          ),
        if (hasTipChanges) userNotifier.updateTipSettings(tipReceiver: _selectedTipReceiver, tipAmount: _selectedTipAmount),
      ], eagerError: false);

      final Map<String, dynamic> profileResult = hasTextInputChanges ? results[0] as Map<String, dynamic> : {'result': "no_changes"};
      final tipResult = hasTipChanges ? results[hasTextInputChanges ? 1 : 0] : "no_changes";

      final bool profileUpdateSuccess =
          profileResult['result'] == "success" || profileResult['result'].toString().startsWith("partial_success");
      final bool tipsUpdateSuccess = tipResult == "success";

      if (profileUpdateSuccess || tipsUpdateSuccess) {
        if (hasTextInputChanges && profileResult.containsKey('updatedCreator')) {
          await userNotifier.updateCreatorProfile(profileResult['updatedCreator']);

          if (hasChangedImgur) {
            await creatorRepo.refreshAndCacheAvatar(user.id, forceRefreshAfterProfileUpdate: true, forceImageType: newImgurUrl.split(".").last);
          }
        }

        if (profileResult['result'].toString().startsWith("partial_success")) {
          showSnackBar(type: SnackbarType.info, "Partially updated: ${profileResult['result']}", context);
        } else if (profileUpdateSuccess && tipsUpdateSuccess) {
          showSnackBar(type: SnackbarType.success, "Profile & Tips updated successfully! ✨", context);
          MemoConfetti().launch(context);
        } else if (profileUpdateSuccess) {
          showSnackBar(type: SnackbarType.success, "Profile updated successfully! ✨", context);
          MemoConfetti().launch(context);
        } else if (tipsUpdateSuccess) {
          showSnackBar(type: SnackbarType.success, "Tips updated successfully! ✨", context);
          MemoConfetti().launch(context);
        }

        user.temporaryTipReceiver = null;
        user.temporaryTipAmount = null;

        ref.invalidate(userProvider);
        ref.invalidate(profileDataProvider);

        onSuccess();
      } else {
        // final failMessage = [
        //   if (hasTextInputChanges) "profile: ${profileResult['result']}",
        //   if (hasTipChanges) "tip settings: $tipResult",
        // ].join(', ');
        if (hasTextInputChanges) {
          try {
            String msg = MemoVerificationResponse.memoVerificationMessageFromName(profileResult['result']);
            showSnackBar(type: SnackbarType.error, "Profile: $msg", context);
          } catch (e) {
            showQrCodeDialog(context: context, memoOnly: true, user: user);
            showSnackBar("Add funds to your balance!", context, type: SnackbarType.error);
            showSnackBar(wait: true, "Name, text and image are stored on-chain, that costs tx fee!", context, type: SnackbarType.info);
          }
          // try {
          //   String msgAccountant = MemoAccountantResponse.messageFromName(profileResult['failedChanges']);
          //   showSnackBar(type: SnackbarType.error, "Profile: $msgAccountant", context);
          // } catch (e) {}
        }
        // if (hasTipChanges) {
        //   try {
        //     String msgVerifier = MemoVerificationResponse.memoVerificationMessageFromName(tipResult.toString());
        //     showSnackBar(type: SnackbarType.error, "Tips: $msgVerifier", context);
        //   } catch (e) {}
        // }
        onFail();
      }
    } catch (e) {
      showSnackBar(type: SnackbarType.error, "Profile/Tips failed: $e", context);
      onFail();
    } finally {
      setState(() {
        _controllersInitialized = false;
        isSavingProfile = false;
      });
      // setState(() => );
    }
  }

  void _showMnemonicBackupDialog() {
    final user = ref.read(userProvider)!;
    showDialog(
      context: context,
      builder: (ctx) => MnemonicBackupWidget(
        mnemonic: user.mnemonic,
        onVerificationComplete: () {
          SharedPreferences.getInstance().then((prefs) {
            prefs.setBool(_mnemonicBackupKey, true);
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

  void _logout() {
    ref.read(authCheckerProvider).logOut();
    ref.read(profileTargetIdProvider.notifier).state = null;
    ref.read(tabIndexProvider.notifier).setTab(AppTab.feed.tabIndex);
  }
}
