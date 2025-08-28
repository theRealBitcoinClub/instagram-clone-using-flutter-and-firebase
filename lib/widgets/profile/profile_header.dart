import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart'; // Adjust path
import 'package:mahakka/memo/model/memo_model_user.dart'; // Adjust path
import 'package:mahakka/widgets/profile_buttons.dart'; // Adjust path

// Helper for logging errors consistently
void _logHeaderError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileHeader - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileHeader extends StatelessWidget {
  final MemoModelCreator creator;
  final MemoModelUser? loggedInUser; // For displaying balances if own profile
  final bool isOwnProfile;
  final bool isRefreshingProfile;
  final VoidCallback onProfileButtonPressed;
  final VoidCallback showImageDetail;
  final Widget Function(ThemeData theme, String title, String count) buildStatColumn;
  final bool showDefaultAvatar; // To manage avatar fallback state

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
          _buildTopDetailsRow(theme, colorScheme, context), // Pass context if showImageDetail needs it indirectly
          _buildNameRow(theme),
          _buildProfileText(colorScheme, theme),
          Divider(color: theme.dividerColor.withOpacity(0.5), height: 1.0, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildTopDetailsRow(ThemeData theme, ColorScheme colorScheme, BuildContext context) {
    final creatorProfileImg = creator.profileImageAvatar();
    final balanceBch = loggedInUser?.balanceBchDevPath145 ?? "0";
    final balanceTokens = loggedInUser?.balanceCashtokensDevPath145 ?? "0";
    final balanceMemo = loggedInUser?.balanceBchDevPath0Memo ?? "0";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), // Added top padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          GestureDetector(
            onTap: showImageDetail, // Callback from parent
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceVariant,
              backgroundImage: showDefaultAvatar || creatorProfileImg.isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creatorProfileImg),
              onBackgroundImageError: (exception, stackTrace) {
                // This error is typically handled by the parent by setting showDefaultAvatar
                _logHeaderError("Error loading profile image in header: ${creator.name}", exception, stackTrace);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensure column doesn't take unnecessary space
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
              children: [
                if (isOwnProfile && loggedInUser != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: buildStatColumn(theme, 'BCH', balanceBch)),
                      Expanded(child: buildStatColumn(theme, 'Tokens', balanceTokens)),
                      Expanded(child: buildStatColumn(theme, 'Posts', balanceMemo)), // Assuming balanceMemo is post count
                    ],
                  )
                else if (!isOwnProfile)
                  Row(
                    // Placeholder for non-own profile stats if needed
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: buildStatColumn(theme, 'Followers', "${creator.followerCount ?? 0}")),
                      Expanded(child: buildStatColumn(theme, 'Actions', "${creator.actions ?? 0}")),
                    ],
                  ),
                const SizedBox(height: 12),
                SettingsButton(
                  // Your themed button
                  text: !isOwnProfile ? "Follow" : 'Edit Profile', // Example
                  onPressed: onProfileButtonPressed,
                  // Add other styling as needed for SettingsButton
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildNameRow(ThemeData theme) {
    final creatorName = creator.name.isNotEmpty ? creator.name : "Anonymous"; // Fallback name
    final creatorProfileIdShort = creator.profileIdShort;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(top: 0, bottom: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          // Use Wrap for better handling of long names + ID
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.0, // Space between name and ID
          children: [
            Text(creatorName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
      return const Padding(padding: EdgeInsets.zero); // Return empty if no text
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
          prefixStyle: theme.textTheme.bodyMedium, // In case you add prefix text
        ),
      ),
    );
  }
}
