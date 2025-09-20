// lib/widgets/profile/profile_header.dart

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';

import '../../memo/model/memo_model_creator.dart';
import 'header/top_details_row.dart';

class ProfileHeader extends StatelessWidget {
  final bool isOwnProfile;
  final bool isRefreshingProfile;
  final VoidCallback onProfileButtonPressed;
  final VoidCallback showImageDetail;
  final bool showDefaultAvatar;
  final MemoModelCreator creator;

  const ProfileHeader({
    Key? key,
    required this.isOwnProfile,
    required this.isRefreshingProfile,
    required this.onProfileButtonPressed,
    required this.showImageDetail,
    required this.showDefaultAvatar,
    required this.creator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildHeaderContent(creator, theme);
  }
  // @override
  // Widget build(BuildContext context, WidgetRef ref) {
  //   final theme = Theme.of(context);
  //
  //   return Consumer(
  //     builder: (context, ref, child) {
  //       final profileDataAsync = ref.watch(profileDataProvider);
  //
  //       return profileDataAsync.when(
  //         skipLoadingOnReload: true,
  //         skipLoadingOnRefresh: true,
  //         skipError: true,
  //         data: (profileData) {
  //           if (profileData.creator == null) return LinearProgressIndicator();
  //           return _buildHeaderContent(profileData.creator!, theme);
  //         },
  //         loading: () => LinearProgressIndicator(),
  //         error: (error, stack) => SizedBox.shrink(),
  //       );
  //     },
  //   );
  // }
  //
  // @override
  // Widget build(BuildContext context, WidgetRef ref) {
  //   final theme = Theme.of(context);
  //   final profileDataAsync = ref.watch(profileDataProvider);
  //
  //   return profileDataAsync.when(
  //     skipLoadingOnReload: true, // Add this
  //     skipLoadingOnRefresh: true, // Add this
  //     skipError: true,
  //     data: (profileData) {
  //       // Safe null handling
  //       if (profileData.creator == null) {
  //         return LinearProgressIndicator();
  //       }
  //       return _buildHeaderContent(profileData.creator!, theme);
  //     },
  //     loading: () => LinearProgressIndicator(),
  //     error: (error, stack) => SizedBox.shrink(),
  //   );
  // }

  Widget _buildHeaderContent(MemoModelCreator creator, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRefreshingProfile) _buildProgressIndicator(),
          ProfileAvatarBalancesButtonRow(
            creator: creator,
            theme: theme,
            showImageDetail: showImageDetail,
            showDefaultAvatar: showDefaultAvatar,
            isOwnProfile: isOwnProfile,
            onProfileButtonPressed: onProfileButtonPressed,
          ),
          _buildNameRow(creator, theme),
          _buildProfileText(creator, theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return const LinearProgressIndicator(
      minHeight: 2.5,
      valueColor: AlwaysStoppedAnimation(Colors.white70),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildNameRow(MemoModelCreator creator, ThemeData theme) {
    var name = creator.nameMaxLengthAware;
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
              name.isNotEmpty ? name : "Anonymous",
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
      padding: const EdgeInsets.fromLTRB(21, 2, 20, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ExpandableText(
          creator.profileText,
          expandText: 'show more',
          collapseText: 'show less',
          maxLines: 2,
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
