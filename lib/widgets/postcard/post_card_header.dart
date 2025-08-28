import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
// Import the new navigation provider
import 'package:mahakka/provider/navigation_providers.dart';
// Import your tab index provider (adjust path if it's elsewhere)
import 'package:mahakka/tab_index_notifier.dart'; // Or wherever TabIndexNotifier/Provider is

// Helper for logging (can be moved to a common utils file if used elsewhere)
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: PostCardHeader - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

// Changed to ConsumerWidget to use ref
class PostCardHeader extends ConsumerWidget {
  final MemoModelPost post;
  final VoidCallback onOptionsMenuPressed; // This is for the "Tip" button

  const PostCardHeader({super.key, required this.post, required this.onOptionsMenuPressed});

  void _navigateToProfile(BuildContext context, WidgetRef ref, String creatorId) {
    // Set the target profile ID using Riverpod
    ref.read(profileTargetIdProvider.notifier).state = creatorId;
    // Switch to the profile tab using Riverpod (assuming 2 is the profile tab index)
    // Ensure tabIndexProvider is correctly imported and defined
    ref.read(tabIndexProvider.notifier).setTab(2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    final ThemeData theme = Theme.of(context);
    // Creator null check should ideally happen before this widget is built,
    // or you can add a fallback here.
    final MemoModelCreator creator = post.creator ?? MemoModelCreator(id: 'unknown', name: 'Unknown'); // Fallback

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16).copyWith(right: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, ref, creator.id), // Pass ref
            child: CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.surfaceVariant,
              backgroundImage: creator.profileImageAvatar().isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creator.profileImageAvatar()),
              onBackgroundImageError: (exception, stackTrace) {
                _logError("Error loading profile image for ${creator.name}", exception, stackTrace);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, ref, creator.id), // Pass ref
                  child: Text(
                    creator.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.age != null || post.created != null)
                  Row(
                    children: [
                      if (post.age != null)
                        Text(post.age!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (post.age != null && post.created != null)
                        Text(" - ", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      if (post.created != null)
                        Text(post.created!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.thumb_up_alt_outlined),
            onPressed: onOptionsMenuPressed, // This is for the "Tip Creator" action
            iconSize: 22,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
