import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/widgets/profile/header/stat_widget.dart';

import '../../../memo/model/memo_model_creator.dart';
import '../../../providers/webview_providers.dart';
import '../../../views_taggable/widgets/qr_code_dialog.dart';
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
    final colorScheme = theme.colorScheme;
    final creatorProfileImg = creator.profileImgurUrl ?? creator.profileImageAvatar();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: showImageDetail,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceVariant,
              backgroundImage: showDefaultAvatar || creatorProfileImg.isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creatorProfileImg),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Expanded(
                    //   child: StatWidget(title: 'BCH', count: creator.balanceBch, theme: theme),
                    // ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => WebViewNavigationHelper.navigateToWebView(ref, WebViewShow.url, MemoBitcoinBase.tokenUrl),
                        child: StatWidget(title: MemoBitcoinBase.tokenTicker, count: creator.balanceToken, theme: theme),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => WebViewNavigationHelper.navigateToWebView(
                          ref,
                          WebViewShow.url,
                          MemoBitcoinBase.memoExplorerUrlPrefix + creator.id + MemoBitcoinBase.memoExplorerUrlSuffix,
                        ),
                        child: StatWidget(title: 'BCH', count: creator.balanceMemo, theme: theme),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SettingsButton(
                    text: !isOwnProfile ? "Send Tip" : 'Edit Profile & Settings',
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

  void _showTipDialog(BuildContext context, ThemeData theme, MemoModelCreator creator) {
    showQrCodeDialog(theme: theme, context: context, creator: creator);
  }
}
