import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/provider/user_provider.dart'; // Import the user provider
import 'package:mahakka/widgets/profile_buttons.dart';

// Helper for logging errors consistently
void _logHeaderError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileHeader - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileHeader extends StatelessWidget {
  final MemoModelCreator creator;
  // The loggedInUser is now a prop used for reference but balances are watched
  final MemoModelUser? loggedInUser;
  final bool isOwnProfile;
  final bool isRefreshingProfile;
  final VoidCallback onProfileButtonPressed;
  final VoidCallback showImageDetail;
  final Widget Function(ThemeData theme, String title, String count) buildStatColumn;
  final bool showDefaultAvatar;

  const ProfileHeader({
    Key? key,
    required this.creator,
    required this.loggedInUser,
    required this.isOwnProfile,
    required this.isRefreshingProfile,
    required this.onProfileButtonPressed,
    required this.showImageDetail,
    required this.buildStatColumn,
    required this.showDefaultAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefreshingProfile)
            const LinearProgressIndicator(
              minHeight: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white70),
              backgroundColor: Colors.transparent,
            ),
          // Wrap the top section in a Consumer to watch the userProvider
          Consumer(
            builder: (context, ref, child) {
              final updatedUser = ref.watch(userProvider);
              return _buildTopDetailsRow(theme, colorScheme, context, updatedUser);
            },
          ),
          _buildNameRow(theme),
          _buildProfileText(colorScheme, theme),
          Divider(color: theme.dividerColor.withOpacity(0.5), height: 2.0, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildTopDetailsRow(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
    MemoModelUser? updatedUser, // The updated user from the provider
  ) {
    final creatorProfileImg = creator.profileImageAvatar();
    // Use updatedUser to get the most recent balance values
    final balanceBch = updatedUser?.balanceBchDevPath145 ?? "?";
    final balanceTokens = updatedUser?.balanceCashtokensDevPath145 ?? "?";
    final balanceMemo = updatedUser?.balanceBchDevPath0Memo ?? "?";
    String balanceBchCreator = creator.balanceBch == -1 ? "?" : creator.balanceBch.toString();
    String balanceTokensCreator = creator.balanceToken == -1 ? "?" : creator.balanceToken.toString();
    String balanceMemoCreator = creator.balanceMemo == -1 ? "?" : creator.balanceMemo.toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: showImageDetail,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceVariant,
              backgroundImage: showDefaultAvatar || creatorProfileImg.isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creatorProfileImg),
              onBackgroundImageError: (exception, stackTrace) {
                _logHeaderError("Error loading profile image in header: ${creator.name}", exception, stackTrace);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOwnProfile && updatedUser != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: buildStatColumn(theme, 'BCH', balanceBch)),
                      Expanded(child: buildStatColumn(theme, 'Tokens', balanceTokens)),
                      Expanded(child: buildStatColumn(theme, 'Memo', balanceMemo)),
                    ],
                  )
                else if (!isOwnProfile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: buildStatColumn(theme, 'BCH', balanceBchCreator)),
                      Expanded(child: buildStatColumn(theme, 'Tokens', balanceTokensCreator)),
                      Expanded(child: buildStatColumn(theme, 'Memo', balanceMemoCreator)),
                    ],
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  child: SettingsButton(text: !isOwnProfile ? "Send Tip" : 'Edit Profile', onPressed: onProfileButtonPressed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildNameRow(ThemeData theme) {
    final creatorName = creator.name.isNotEmpty ? creator.name : "Anonymous";
    final creatorProfileIdShort = creator.profileIdShort;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(top: 2, bottom: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.0,
          children: [
            Text(creatorName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (creatorProfileIdShort.isNotEmpty)
              Text(
                creatorProfileIdShort,
                style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }

  Padding _buildProfileText(ColorScheme colorScheme, ThemeData theme) {
    final profileText = creator.profileText;
    if (profileText.trim().isEmpty) {
      return const Padding(padding: EdgeInsets.zero);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 2, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ExpandableText(
          profileText,
          expandText: 'show more',
          collapseText: 'show less',
          maxLines: 3,
          linkColor: colorScheme.primary,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4, color: theme.colorScheme.onSurface.withOpacity(0.85)),
          linkStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
          prefixStyle: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
