import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';

import '../../provider/post_update_provider.dart';
import '../../providers/navigation_providers.dart';
import '../../providers/token_limits_provider.dart';
import '../cached_avatar.dart';

class PostCardHeader extends ConsumerWidget {
  final MemoModelPost post;
  final VoidCallback onLikePostTipCreator;
  final int? index;

  const PostCardHeader({super.key, required this.post, required this.onLikePostTipCreator, this.index});

  void _navigateToProfile(BuildContext context, WidgetRef ref, String creatorId) {
    ref.read(navigationStateProvider.notifier).navigateToCreatorProfile(creatorId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final MemoModelCreator creator = post.creator ?? MemoModelCreator(id: post.creatorId, name: post.creatorId); // Fallback
    final popularityUpdates = ref.watch(postPopularityProvider);
    final feedLimit = ref.watch(feedLimitProvider);
    final updatedScore = popularityUpdates[post.id!];
    final displayScore = updatedScore ?? post.popularityScore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 3, 3),
      child: Row(
        children: [
          CachedAvatar(
            showMuteBadge: false,
            key: ValueKey('post_avatar_${creator.id}_${post.id}'), // Include refresh state in key
            creatorId: creator.id,
            radius: 27,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                onTap: () => _navigateToProfile(context, ref, creator.id), // Pass ref
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 3, horizontal: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text("${creator.profileIdShort} ", style: theme.textTheme.titleSmall),
                          Expanded(
                            child: Text(creator.nameMaxLengthAware, style: theme.textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      buildCounterDateAgeRow(feedLimit, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Spacer(),
          buildPopularityCounterTipPost(displayScore),
        ],
      ),
    );
  }

  Widget buildPopularityCounterTipPost(int displayScore) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(9)),
        onTap: onLikePostTipCreator,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 0, 0, 0),
          child: Row(
            children: [
              PopularityScoreWidget(initialScore: displayScore, postId: post.id, textStyleBalance: true),
              IconButton(
                padding: EdgeInsets.all(18),
                icon: const Icon(Icons.thumb_up_alt_outlined),
                onPressed: onLikePostTipCreator, // This is for the "Tip Creator" action
                iconSize: 25.2,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row buildCounterDateAgeRow(int feedLimit, ThemeData theme) {
    return Row(
      children: [
        if (index != null)
          Text(
            "[${(index! + 1).toString().padLeft(2, '0')}/$feedLimit] ",
            style: theme.textTheme.titleSmall!.copyWith(color: theme.colorScheme.secondary.withAlpha(153)),
          ),
        if (post.createdDateTime != null)
          Text(
            "${post.dateTimeFormattedSafe()}: ",
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha(169)),
          ),
        if (post.age.isNotEmpty && post.createdDateTime != null)
          Text("", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (post.age.isNotEmpty) Text(post.age, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
