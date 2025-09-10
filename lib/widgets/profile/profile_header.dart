import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';

import '../../memo/model/memo_model_creator.dart';
import '../../provider/profile_providers.dart';
import 'header/top_details_row.dart';

class ProfileHeader extends ConsumerWidget {
  final MemoModelCreator creator;
  final bool isOwnProfile;
  final bool isRefreshingProfile;
  final VoidCallback onProfileButtonPressed;
  final VoidCallback showImageDetail;
  final bool showDefaultAvatar;

  const ProfileHeader({
    Key? key,
    required this.creator,
    required this.isOwnProfile,
    required this.isRefreshingProfile,
    required this.onProfileButtonPressed,
    required this.showImageDetail,
    required this.showDefaultAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final creatorAsync = ref.watch(profileCreatorStateProvider);

    return creatorAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (creator) => _buildHeaderContent(creator!, theme),
      loading: () => LinearProgressIndicator(),
      error: (error, stack) => Text("Please kill and restart the app"),
    );
  }

  Widget _buildHeaderContent(MemoModelCreator creator, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefreshingProfile) _buildProgressIndicator(),
          ProfileAvatarBalancesButtonRow(
            creator: creator, // Use the provider data directly
            theme: theme,
            showImageDetail: showImageDetail,
            showDefaultAvatar: showDefaultAvatar,
            isOwnProfile: isOwnProfile,
            onProfileButtonPressed: onProfileButtonPressed,
          ),
          _buildNameRow(creator, theme),
          _buildProfileText(creator, theme),
          const Divider(height: 2.0, thickness: 0.5),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context, WidgetRef ref) {
  //   final theme = Theme.of(context);
  //   final updatedCreator = ref.watch(profileCreatorStateProvider).asData?.value ?? creator;
  //
  //   return Container(
  //     decoration: BoxDecoration(color: theme.colorScheme.surface),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         if (isRefreshingProfile) _buildProgressIndicator(),
  //         TopDetailsRow(
  //           creator: updatedCreator,
  //           theme: theme,
  //           showImageDetail: showImageDetail,
  //           showDefaultAvatar: showDefaultAvatar,
  //           isOwnProfile: isOwnProfile,
  //           onProfileButtonPressed: onProfileButtonPressed,
  //         ),
  //         _buildNameRow(updatedCreator, theme),
  //         _buildProfileText(updatedCreator, theme),
  //         const Divider(height: 2.0, thickness: 0.5),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildProgressIndicator() {
    return const LinearProgressIndicator(
      minHeight: 2.5,
      valueColor: AlwaysStoppedAnimation(Colors.white70),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildNameRow(MemoModelCreator creator, ThemeData theme) {
    var name = creator.name;
    var maxLength = MemoVerifier.maxProfileNameLength;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          spacing: 6.0,
          children: [
            Text(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              name.isNotEmpty ? name.substring(0, name.length < maxLength ? name.length : maxLength) : "Anonymous",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Spacer(),
            if (creator.profileIdShort.isNotEmpty) Text(creator.profileIdShort, style: _profileIdStyle(theme)),
          ],
        ),
      ),
    );
  }

  TextStyle? _profileIdStyle(ThemeData theme) {
    return theme.textTheme.titleSmall?.copyWith(letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant);
  }

  Widget _buildProfileText(MemoModelCreator creator, ThemeData theme) {
    if (creator.profileText.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(21, 2, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ExpandableText(
          creator.profileText,
          expandText: 'show more',
          collapseText: 'show less',
          maxLines: 3,
          linkColor: theme.colorScheme.primary,
          style: _profileTextStyle(theme),
          linkStyle: _profileLinkStyle(theme),
        ),
      ),
    );
  }

  TextStyle? _profileTextStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(height: 1.4, color: theme.colorScheme.onSurface.withOpacity(0.85));
  }

  TextStyle? _profileLinkStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary);
  }
}
