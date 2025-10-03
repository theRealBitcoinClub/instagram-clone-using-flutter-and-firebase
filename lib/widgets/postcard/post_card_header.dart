import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';

import '../../provider/mute_creator_provider.dart';
import '../../provider/post_update_provider.dart';
import '../../providers/navigation_providers.dart';
import '../../utils/snackbar.dart';
import '../cached_avatar.dart';
import '../muted_creators_dialog.dart';

class PostCardHeader extends ConsumerWidget {
  final MemoModelPost post;
  final VoidCallback onLikePostTipCreator;

  const PostCardHeader({super.key, required this.post, required this.onLikePostTipCreator});

  void _navigateToProfile(BuildContext context, WidgetRef ref, String creatorId) {
    ref.read(navigationStateProvider.notifier).navigateToCreatorProfile(creatorId);
    // ref.read(profileTargetIdProvider.notifier).state = creatorId;
    // ref.read(tabIndexProvider.notifier).setTab(AppTab.profile.tabIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MemoModelCreator creator = post.creator ?? MemoModelCreator(id: post.creatorId, name: post.creatorId); // Fallback
    final popularityUpdates = ref.watch(postPopularityProvider);
    final updatedScore = popularityUpdates[post.id!];
    final displayScore = updatedScore ?? post.popularityScore;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12).copyWith(right: 3),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () {
              ref
                  .read(muteCreatorProvider.notifier)
                  .muteCreator(
                    creator.id,
                    onMuteSuccess: () {
                      showSnackBar("MUTED CREATOR: ${creator.name}", type: SnackbarType.success);
                      showMutedCreatorsDialog(context);
                    },
                    onMutedAlready: () {
                      showSnackBar("CREATOR ALREADY MUTED: ${creator.name}", type: SnackbarType.info);
                      showMutedCreatorsDialog(context);
                    },
                  );
            },
            child: Icon(Icons.block_outlined, color: theme.colorScheme.error),
          ),
          CachedAvatar(
            key: ValueKey('post_avatar_${creator.id}_${post.id}'), // Include refresh state in key
            creatorId: creator.id,
            radius: 27,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, ref, creator.id), // Pass ref
                  child: Row(
                    children: [
                      Text("${creator.profileIdShort} ", style: theme.textTheme.titleSmall),
                      SizedBox(
                        width: 171,
                        child: Text(creator.nameMaxLengthAware, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    if (post.createdDateTime != null)
                      Text(
                        post.dateTimeFormattedSafe(),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha(169)),
                      ),
                    if (post.age.isNotEmpty && post.createdDateTime != null)
                      Text(" - ", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    if (post.age.isNotEmpty)
                      Text(post.age, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLikePostTipCreator,
            child: Row(
              children: [
                PopularityScoreWidget(initialScore: displayScore, postId: post.id),
                // Text("${post.popularityScore}", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w400)),
                SizedBox(width: 3),
                IconButton(
                  padding: EdgeInsets.all(9),
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                  onPressed: onLikePostTipCreator, // This is for the "Tip Creator" action
                  iconSize: 21,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
