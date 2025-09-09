import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/feed_posts_provider.dart';

class PostCounterWidget extends ConsumerWidget {
  const PostCounterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedState = ref.watch(feedPostsProvider);
    final notifier = ref.read(feedPostsProvider.notifier);

    // Listen for F5 key to trigger refresh
    RawKeyboard.instance.addListener((event) {
      if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.f5) {
        notifier.refreshFeed();
      }
    });

    if (!feedState.showPostCounter) return const SizedBox.shrink();

    //TODO the last feed state must be persisted locally to make this check work well
    //TODO lastPostCount of last refresh must be checked against the new totalPostCount
    final newPostsCount = feedState.totalPostCount - feedState.posts.length;

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12.0)),
      child: Row(
        children: [
          Icon(Icons.update, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'There are $newPostsCount new posts available, pull to refresh',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () => notifier.hidePostCounter(),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
