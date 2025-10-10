// lib/widgets/profile/settings_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
import 'package:mahakka/widgets/bch/mnemonic_backup_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:mahakka/widgets/muted_creators_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider/profile_data_model_provider.dart';
import '../../provider/translation_service.dart';
import '../../provider/user_provider.dart';
import '../../providers/navigation_providers.dart';
import '../../repositories/creator_repository.dart';
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
  bool _inputControllersInitialized = false;

  late TabController _tabController;
  int _currentTabIndex = 0;

  // DRY text constants
  static const String _closeDialogText = "CLOSE";
  static const String _saveChangesText = "save";
  static const String _mutedCreatorsText = "MUTED";
  static const String _replayIntroText = "INTRO";
  static const String _backupText = "BACKUP";
  static const String _logoutText = "LOGOUT";
  static const String _nameHintText = "Name";
  static const String _bioHintText = "Bio/Text";
  static const String _imgurHintText = "e.g. https://i.imgur.com/X32JJS.jpg";
  static const String _tipReceiverLabel = "Tip Receiver";
  static const String _tipAmountLabel = "Tip Amount";
  static const String _noChangesText = "No changes to save. 🤔";
  static const String _profileTipsSuccessText = "Profile & Tips updated successfully! ✨";
  static const String _profileSuccessText = "Profile updated successfully! ✨";
  static const String _tipsSuccessText = "Tips updated successfully! ✨";
  static const String _profileFailedText = "Profile/Tips failed:";
  static const String _onChainCostText = "Name, text and image are stored on-chain, that costs memo fee!";
  static const String _addFundsText = "Add funds to your balance!";

  List<Widget> tabs() {
    return const [
      // Tab(icon: Icon(Icons.account_circle_outlined), text: 'Creator'),
      // Tab(icon: Icon(Icons.currency_bitcoin_rounded), text: 'Tips'),
      // Tab(icon: Icon(Icons.settings), text: 'User'),
      Tab(height: 64, icon: Icon(Icons.account_circle_outlined, size: 36)),
      Tab(height: 64, icon: Icon(Icons.currency_bitcoin_rounded, size: 36)),
      Tab(height: 64, icon: Icon(Icons.settings, size: 36)),
    ];
  }

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
    if (_inputControllersInitialized) return;

    _profileNameCtrl.text = creator.name;
    _profileTextCtrl.text = creator.profileText;
    _imgurCtrl.text = creator.profileImgurUrl ?? "";
    _selectedTipReceiver = user.tipReceiver;
    _selectedTipAmount = user.tipAmountEnum;

    _inputControllersInitialized = true;
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
    final user = ref.watch(userProvider)!;
    _mnemonicBackupKey = 'mnemonic_backup_verified${user.id}';

    final profileDataAsync = ref.watch(profileDataNotifier);

    return profileDataAsync.when(
      loading: () => _buildLoadingWidget(theme),
      error: (error, stack) => _buildErrorWidget(theme, "Failed to load creator: $error"),
      data: (profileData) {
        if (!_inputControllersInitialized) {
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 441),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String error) {
    return Dialog(
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 441),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                // Partial translation - only translate the prefix, keep error details as-is
                final parts = error.split(': ');
                if (parts.length > 1) {
                  final translatedPrefix = ref.watch(autoTranslationTextProvider(parts[0]));
                  return Text(
                    '${translatedPrefix.value ?? parts[0]}: ${parts.sublist(1).join(': ')}',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  );
                } else {
                  final translatedError = ref.watch(autoTranslationTextProvider(error));
                  return Text(translatedError.value ?? error, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center);
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Consumer(
                builder: (context, ref, child) {
                  final translatedClose = ref.watch(autoTranslationTextProvider('Close'));
                  return Text(translatedClose.value ?? 'Close');
                },
              ),
            ),
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 441),
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
            if (isSavingProfile)
              AnimGrowFade(
                show: isSavingProfile,
                child: Padding(padding: EdgeInsets.only(top: 16, bottom: 0), child: LinearProgressIndicator()),
              ),
            _buildBottomButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(ThemeData theme) {
    return Container(
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
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                unselectedLabelStyle: theme.textTheme.labelMedium,
                labelStyle: theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold),
                indicator: BoxDecoration(color: theme.colorScheme.onSurface.withAlpha(12)),
                indicatorPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                tabs: tabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            IconAction(text: _closeDialogText, onTap: _onClose, type: IAB.cancel, icon: Icons.cancel_outlined),
            IconAction(text: _saveChangesText, onTap: _onSavePressed, type: IAB.success, icon: Icons.save),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTab(ThemeData theme, MemoModelUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsOptionWidget(
            theme: theme,
            icon: Icons.block_outlined,
            text: _mutedCreatorsText,
            dialogContext: context,
            onSelect: () => showMutedCreatorsDialog(context),
          ),
          SettingsOptionWidget(
            theme: theme,
            icon: Icons.info_outline,
            text: _replayIntroText,
            dialogContext: context,
            onSelect: () => _replayIntros(),
          ),
          const Divider(),
          SettingsOptionWidget(
            theme: theme,
            icon: Icons.security_outlined,
            text: _backupText,
            dialogContext: context,
            onSelect: _showMnemonicBackupDialog,
          ),
          SettingsOptionWidget(
            theme: theme,
            icon: Icons.logout_rounded,
            text: _logoutText,
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
            maxLength: MemoVerifier.maxProfileNameLength,
            theme: theme,
            icon: Icons.badge_outlined,
            hintText: _nameHintText,
            type: TextInputType.text,
            controller: _profileNameCtrl,
          ),
          const SizedBox(height: 0),
          SettingsInputWidget(
            maxLength: MemoVerifier.maxProfileTextLength,
            theme: theme,
            icon: Icons.notes_outlined,
            hintText: _bioHintText,
            type: TextInputType.multiline,
            controller: _profileTextCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 0),
          SettingsInputWidget(
            theme: theme,
            icon: Icons.image_outlined,
            hintText: _imgurHintText,
            type: TextInputType.url,
            controller: _imgurCtrl,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildTipReceiverDropdown(theme), const SizedBox(height: 20), _buildTipAmountDropdown(theme)],
      ),
    );
  }

  Widget _buildTipReceiverDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Consumer(
          builder: (context, ref, child) {
            final translatedLabel = ref.watch(autoTranslationTextProvider(_tipReceiverLabel));
            return Text(translatedLabel.value ?? _tipReceiverLabel, style: theme.textTheme.labelSmall);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipReceiver>(
          value: _selectedTipReceiver,
          onChanged: (TipReceiver? newValue) {
            setState(() {
              _selectedTipReceiver = newValue;
            });
          },
          items: TipReceiver.values.map((TipReceiver receiver) {
            return DropdownMenuItem<TipReceiver>(
              value: receiver,
              child: Consumer(
                builder: (context, ref, child) {
                  final translatedDisplayName = ref.watch(autoTranslationTextProvider(receiver.displayName));
                  return Text(translatedDisplayName.value ?? receiver.displayName);
                },
              ),
            );
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
        Consumer(
          builder: (context, ref, child) {
            final translatedLabel = ref.watch(autoTranslationTextProvider(_tipAmountLabel));
            return Text(translatedLabel.value ?? _tipAmountLabel, style: theme.textTheme.labelSmall);
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipAmount>(
          value: _selectedTipAmount,
          onChanged: (TipAmount? newValue) {
            setState(() {
              _selectedTipAmount = newValue;
            });
          },
          items: TipAmount.values.map((TipAmount amount) {
            return DropdownMenuItem<TipAmount>(
              value: amount,
              child: Consumer(
                builder: (context, ref, child) {
                  final displayName = _getTipAmountDisplayName(amount);
                  final translatedDisplayName = ref.watch(autoTranslationTextProvider(displayName));
                  return Text(translatedDisplayName.value ?? displayName);
                },
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _onClose() {
    FocusScope.of(context).unfocus();
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  String _getTipAmountDisplayName(TipAmount amount) {
    final String name = amount.name[0].toUpperCase() + amount.name.substring(1);
    final formattedValue = amount.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return "$name ($formattedValue satoshis)";
  }

  void _onSavePressed() {
    if (isSavingProfile) return;

    FocusScope.of(context).unfocus();
    _saveProfile(() => Navigator.of(context).pop(), () {});
  }

  void _saveProfile(Function onSuccess, Function onFail) async {
    setState(() => isSavingProfile = true);

    try {
      final user = ref.read(userProvider)!;
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final userNotifier = ref.read(userNotifierProvider.notifier);
      final creatorAsync = ref.read(profileDataNotifier);

      MemoModelCreator creator = creatorAsync.value!.creator!;

      final newName = _profileNameCtrl.text.trim();
      final newText = _profileTextCtrl.text.trim();
      final newImgurUrl = _imgurCtrl.text.trim();

      var hasChangedImgur = newImgurUrl.isNotEmpty && newImgurUrl != creator.profileImgurUrl;
      final bool hasTextInputChanges = (newName.isNotEmpty && newName != creator.name) || (newText != creator.profileText) || (hasChangedImgur);

      final bool hasTipChanges =
          (_selectedTipReceiver != null && _selectedTipReceiver != user.tipReceiver) ||
          (_selectedTipAmount != null && _selectedTipAmount != user.tipAmountEnum);

      if (!hasTextInputChanges && !hasTipChanges) {
        ref.read(snackbarServiceProvider).showTranslatedSnackBar(_noChangesText, type: SnackbarType.info);
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
          ref
              .read(snackbarServiceProvider)
              .showTranslatedSnackBar("Partially updated: ${profileResult['result'].toString()}", type: SnackbarType.info);
        } else if (profileUpdateSuccess && tipsUpdateSuccess) {
          ref.read(snackbarServiceProvider).showTranslatedSnackBar(_profileTipsSuccessText, type: SnackbarType.success);
          MemoConfetti().launch(context);
        } else if (profileUpdateSuccess) {
          ref.read(snackbarServiceProvider).showTranslatedSnackBar(_profileSuccessText, type: SnackbarType.success);
          MemoConfetti().launch(context);
        } else if (tipsUpdateSuccess) {
          ref.read(snackbarServiceProvider).showTranslatedSnackBar(_tipsSuccessText, type: SnackbarType.success);
          MemoConfetti().launch(context);
        }

        user.temporaryTipReceiver = null;
        user.temporaryTipAmount = null;

        ref.invalidate(userProvider);

        setState(() {
          _inputControllersInitialized = false;
        });
        onSuccess();
      } else {
        if (hasTextInputChanges) {
          try {
            String msg = MemoVerificationResponse.memoVerificationMessageFromName(profileResult['result']);
            ref.read(snackbarServiceProvider).showTranslatedSnackBar(msg, type: SnackbarType.error);
          } catch (e) {
            ref.read(snackbarServiceProvider).showTranslatedSnackBar(_onChainCostText, type: SnackbarType.error, wait: true);
            showQrCodeDialog(ctx: context, memoOnly: true, user: user, withDelay: true);
          }
        }
        onFail();
      }
    } catch (e) {
      ref
          .read(snackbarServiceProvider)
          .showPartiallyTranslatedSnackBar(translateable: _profileFailedText, fixedAfter: e.toString(), type: SnackbarType.error);
      onFail();
    } finally {
      setState(() {
        isSavingProfile = false;
      });
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

  void _logout() async {
    if (allowLogout) {
      ref.read(navigationStateProvider.notifier).logoutAndNavigateToFeed();
    } else {
      ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, "You have to backup your secret key first.");
      Future.delayed(Duration(seconds: 3), () {
        if (context.mounted) Navigator.pop(context);
        _showMnemonicBackupDialog();
      });
    }
  }

  void _replayIntros() {
    ref.read(introStateNotifierProvider.notifier).resetAllIntros();
    ref.read(navigationStateProvider.notifier).navigateToFeed();
  }
}
