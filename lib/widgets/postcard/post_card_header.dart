import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
// Import the new navigation provider
import 'package:mahakka/provider/navigation_providers.dart';

import '../../providers/creator_avatar_provider.dart';

// Helper for logging (can be moved to a common utils file if used elsewhere)
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: PostCardHeader - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

// Changed to ConsumerWidget to use ref
class PostCardHeader extends ConsumerWidget {
  final MemoModelPost post;
  final VoidCallback onOptionsMenuPressed;
  // final MemoModelCreator creator;

  const PostCardHeader({super.key, required this.post, required this.onOptionsMenuPressed});

  void _navigateToProfile(BuildContext context, WidgetRef ref, String creatorId) {
    // Set the target profile ID using Riverpod
    ref.read(profileTargetIdProvider.notifier).state = creatorId;
    // Switch to the profile tab using Riverpod (assuming 2 is the profile tab index)
    // Ensure tabIndexProvider is correctly imported and defined
    ref.read(tabIndexProvider.notifier).setTab(2);
    //TODO use enum force use enum for tab index
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    final ThemeData theme = Theme.of(context);
    // Creator null check should ideally happen before this widget is built,
    // or you can add a fallback here.
    final MemoModelCreator creator = post.creator ?? MemoModelCreator(id: 'unknown', name: 'Unknown'); // Fallback
    // Watch the avatar provider to get the avatar URL.
    final avatarAsyncValue = ref.watch(creatorAvatarProvider(post.creator!.id));

    String avatarUrl = creator.profileImageAvatar();

    // The when() method is called with a data, loading and error handler to return a widget.
    // This allows for asynchronous UI updates.
    avatarAsyncValue.when(
      data: (url) {
        // If the provider successfully fetched an avatar URL, update the local variable.
        if (url != null) {
          avatarUrl = url;
        }
      },
      loading: () {
        // We can just keep the existing avatar URL while loading.
        // The UI will show whatever is already there.
      },
      error: (e, s) {
        // Log the error but don't disrupt the rest of the UI.
        print("Error fetching avatar for ${creator.id}: $e");
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16).copyWith(right: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, ref, creator.id), // Pass ref
            child: creator.hasRegisteredAsUser
                ? wrapWithBadge(context, theme, creator, buildCircleAvatar(theme, creator, avatarUrl))
                : buildCircleAvatar(theme, creator, avatarUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, ref, creator.id), // Pass ref
                  child: Row(
                    children: [
                      Text(
                        "${creator.profileIdShort}  ",
                        style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        creator.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (post.age.isNotEmpty)
                      Text(post.age, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (post.age.isNotEmpty && post.createdDateTime != null)
                      Text(" - ", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (post.createdDateTime != null)
                      Text(
                        post.createdDateTime!.toIso8601String(),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.all(10),
            icon: const Icon(Icons.thumb_up_alt_outlined),
            onPressed: onOptionsMenuPressed, // This is for the "Tip Creator" action
            iconSize: 22,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  CircleAvatar buildCircleAvatar(ThemeData theme, MemoModelCreator creator, String avatarUrl) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: theme.colorScheme.surfaceVariant,
      backgroundImage: avatarUrl.isEmpty ? const AssetImage("assets/images/default_profile.png") as ImageProvider : NetworkImage(avatarUrl),
      onBackgroundImageError: (exception, stackTrace) {
        _logError("Error loading profile image for ${creator.name}", exception, stackTrace);
      },
    );
  }

  badges.Badge wrapWithBadge(BuildContext context, ThemeData theme, MemoModelCreator creator, wrappedItem) {
    return badges.Badge(
      position: badges.BadgePosition.topEnd(top: -2, end: -6),
      showBadge: creator.hasRegisteredAsUser,
      onTap: () {},
      badgeContent: Icon(
        Icons.currency_bitcoin_rounded,
        color: Theme.of(context).colorScheme.onPrimary, // Example for theme-aware icon color
        size: 15,
      ),
      badgeAnimation: badges.BadgeAnimation.fade(
        animationDuration: Duration(milliseconds: 5000),
        // colorChangeAnimationDuration: Duration(milliseconds: 100),
        loopAnimation: true,
        colorChangeAnimationCurve: Curves.fastOutSlowIn,
      ),
      badgeStyle: badges.BadgeStyle(
        shape: badges.BadgeShape.circle,
        badgeColor: Theme.of(context).colorScheme.primary, // Use a theme-aware color for the badge background
        padding: EdgeInsets.all(1.5),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface, // Use theme-aware color for the border
          width: 0.8,
        ),
        elevation: 0,
      ),
      child: wrappedItem,
    );
  }
}
