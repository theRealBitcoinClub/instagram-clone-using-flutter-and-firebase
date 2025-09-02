import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/widgets/profile/profile_dialog_helpers.dart';
import 'package:mahakka/widgets/profile_buttons.dart';

import '../../provider/profile_providers.dart';

// Helper for logging errors consistently
void _logHeaderError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileHeader - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileHeader extends StatefulWidget {
  final MemoModelCreator creator;
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
  _ProfileHeaderState createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _isCashtokenFormat = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isRefreshingProfile)
            const LinearProgressIndicator(
              minHeight: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white70),
              backgroundColor: Colors.transparent,
            ),
          Consumer(
            builder: (context, ref, child) {
              final creatorAsyncValue = ref.watch(profileCreatorStateProvider);
              final updatedCreator = creatorAsyncValue.asData?.value ?? widget.creator;
              //TODO is this executed with null value here ever?

              return Column(
                children: [
                  _buildTopDetailsRow(theme, colorScheme, context, updatedCreator),
                  _buildNameRow(updatedCreator, theme),
                  _buildProfileText(updatedCreator, colorScheme, theme),
                ],
              );
            },
          ),
          Divider(color: theme.dividerColor.withOpacity(0.5), height: 2.0, thickness: 0.5),
        ],
      ),
    );
  }

  Widget _buildTopDetailsRow(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
    MemoModelCreator creatorToDisplay, // The updated creator data is now passed in
  ) {
    final creatorProfileImg = creatorToDisplay.profileImageAvatar();
    String balanceBchCreator = creatorToDisplay.balanceBch == -1 ? "?" : creatorToDisplay.balanceBch.toString();
    String balanceTokensCreator = creatorToDisplay.balanceToken == -1 ? "?" : creatorToDisplay.balanceToken.toString();
    String balanceMemoCreator = creatorToDisplay.balanceMemo == -1 ? "?" : creatorToDisplay.balanceMemo.toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: widget.showImageDetail,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceVariant,
              backgroundImage: widget.showDefaultAvatar || creatorProfileImg.isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creatorProfileImg),
              onBackgroundImageError: (exception, stackTrace) {
                _logHeaderError("Error loading profile image in header: ${creatorToDisplay.name}", exception, stackTrace);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(child: widget.buildStatColumn(theme, 'BCH', balanceBchCreator)),
                    Expanded(child: widget.buildStatColumn(theme, 'Tokens', balanceTokensCreator)),
                    Expanded(child: widget.buildStatColumn(theme, 'Memo', balanceMemoCreator)),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                  child: SettingsButton(
                    text: !widget.isOwnProfile ? "Send Tip" : 'Edit Profile',
                    onPressed: () {
                      if (!widget.isOwnProfile) {
                        showQrCodeDialog(
                          theme: theme,
                          context: context,
                          creator: creatorToDisplay,
                          getTempToggleState: () => _isCashtokenFormat,
                          setTempToggleState: (newState) {
                            setState(() {
                              _isCashtokenFormat = newState;
                            });
                          },
                        );
                      } else {
                        widget.onProfileButtonPressed();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildNameRow(MemoModelCreator c, ThemeData theme) {
    final creatorName = c.name.isNotEmpty ? c.name : "Anonymous";
    final creatorProfileIdShort = c.profileIdShort;

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

  Padding _buildProfileText(MemoModelCreator c, ColorScheme colorScheme, ThemeData theme) {
    final profileText = c.profileText;
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
