import 'package:flutter/material.dart';
import 'package:mahakka/widgets/profile/header/stat_widget.dart';

import '../../../memo/model/memo_model_creator.dart';
import '../../../views_taggable/widgets/qr_code_dialog.dart';
import '../profile_buttons.dart';

class TopDetailsRow extends StatelessWidget {
  final MemoModelCreator creator;
  final ThemeData theme;
  final VoidCallback showImageDetail;
  final bool showDefaultAvatar;
  final bool isOwnProfile;
  final VoidCallback onProfileButtonPressed;

  const TopDetailsRow({
    Key? key,
    required this.creator,
    required this.theme,
    required this.showImageDetail,
    required this.showDefaultAvatar,
    required this.isOwnProfile,
    required this.onProfileButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    Expanded(
                      child: StatWidget(title: 'BCH', count: _formatBalance(creator.balanceBch), theme: theme),
                    ),
                    Expanded(
                      child: StatWidget(title: 'Tokens', count: _formatBalance(creator.balanceToken), theme: theme),
                    ),
                    Expanded(
                      child: StatWidget(title: 'Memo', count: _formatBalance(creator.balanceMemo), theme: theme),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: SettingsButton(
                    text: !isOwnProfile ? "Send Tip" : 'Edit Profile',
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

  String _formatBalance(int balance) {
    return balance == -1 ? "?" : balance.toString();
  }

  void _showTipDialog(BuildContext context, ThemeData theme, MemoModelCreator creator) {
    showQrCodeDialog(theme: theme, context: context, creator: creator);
  }
}
