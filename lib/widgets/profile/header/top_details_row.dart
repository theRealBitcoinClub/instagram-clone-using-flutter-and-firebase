import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/profile/header/stat_widget.dart';

import '../../../memo/model/memo_model_creator.dart';
import '../../../views_taggable/widgets/qr_code_dialog.dart';
import '../../cached_avatar.dart';
import '../profile_buttons.dart';

class ProfileAvatarBalancesButtonRow extends ConsumerWidget {
  final MemoModelCreator creator;
  final ThemeData theme;
  final VoidCallback showImageDetail;
  final bool showDefaultAvatar;
  final bool isOwnProfile;
  final VoidCallback onProfileButtonPressed;

  const ProfileAvatarBalancesButtonRow({
    Key? key,
    required this.creator,
    required this.theme,
    required this.showImageDetail,
    required this.showDefaultAvatar,
    required this.isOwnProfile,
    required this.onProfileButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var text = !isOwnProfile ? "Gift" : 'Settings';
    text = ref.watch(autoTranslationTextProvider(text)).value ?? text;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 15, 15, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: showImageDetail,
            child: CachedAvatar(key: ValueKey('profile_avatar_${creator.id}'), creatorId: creator.id, radius: 45, enableNavigation: false),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildStatsRow(ref),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SettingsButtonUniversal(
                    buttonType: ButtonType.outlined,
                    text: text,
                    onPressed: isOwnProfile ? onProfileButtonPressed : () => _showTipDialog(context, theme, creator),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row buildStatsRow(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: StatWidget(
            title: 'BCH',
            count: creator.balanceBch,
            theme: theme,
            onTap: () => creator.bchAddressCashtokenAware.isEmpty
                ? ref.read(snackbarServiceProvider).showTranslatedSnackBar("User has not registered on Mahakka", type: SnackbarType.info)
                : ref.read(navigationStateProvider.notifier).navigateToUrl(MemoBitcoinBase.cashonizeUrl),
          ),
        ),
        Expanded(
          child: StatWidget(
            hasDecimals: true,
            title: MemoBitcoinBase.tokenTicker,
            count: creator.balanceToken,
            theme: theme,
            onTap: () => creator.bchAddressCashtokenAware.isEmpty
                ? ref.read(snackbarServiceProvider).showTranslatedSnackBar("User has not registered on Mahakka", type: SnackbarType.info)
                : ref.read(navigationStateProvider.notifier).navigateToUrl(MemoBitcoinBase.cauldronSwapTokenUrl),
          ),
        ),
        Expanded(
          child: StatWidget(
            title: 'MEMO',
            count: creator.balanceMemo,
            theme: theme,
            onTap: () => ref
                .read(navigationStateProvider.notifier)
                .navigateToUrl(MemoBitcoinBase.memoExplorerUrlPrefix + creator.id + MemoBitcoinBase.memoExplorerUrlSuffix),
          ),
        ),
      ],
    );
  }

  void _showTipDialog(BuildContext context, ThemeData theme, MemoModelCreator creator) {
    showQrCodeDialog(ctx: context, creator: creator);
  }
}
