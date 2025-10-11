import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedScrollController extends StateNotifier<ScrollController?> {
  FeedScrollController() : super(null);

  void setController(ScrollController controller) {
    state = controller;
  }

  void resetScroll() {
    if (state != null && state!.hasClients) {
      state!.jumpTo(0);
    }
  }

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }

  void scrollDownForPost() {
    if (state == null || !state!.hasClients) {
      return;
    }

    final targetPosition = state!.offset + 120.0;

    final maxScrollExtent = state!.position.maxScrollExtent;
    final clampedPosition = targetPosition.clamp(state!.position.minScrollExtent, maxScrollExtent);

    state!.animateTo(clampedPosition, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
}

final feedScrollControllerProvider = StateNotifierProvider<FeedScrollController, ScrollController?>((ref) {
  return FeedScrollController();
});

//
// context.afterLayout(refreshUI: false, () {
//   _print('FSCR:🎯 Requesting focus for list view');
//   FocusScope.of(context).requestFocus(_listViewFocusNode);
//   // Future.delayed(Duration(seconds: 3), () {
//   //   ref.read(tokenLimitsProvider.notifier).handleCreatorUpdate(null);
//   // });
// });

// FocusableActionDetector(
//   autofocus: true,
//   focusNode: _listViewFocusNode,
//   shortcuts: _getKeyboardShortcuts(),
//   actions: <Type, Action<Intent>>{
//     ScrollUpIntent: CallbackAction<ScrollUpIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
//     ScrollDownIntent: CallbackAction<ScrollDownIntent>(onInvoke: (intent) => _handleScrollIntent(intent, context)),
//   },
//   child:
// GestureDetector(
// onTap: () {
//   if (!_listViewFocusNode.hasFocus) {
//     _print('FSCR:🎯 Requesting focus via GestureDetector tap');
//     FocusScope.of(context).requestFocus(_listViewFocusNode);
//   }
// },
// child:

// void _scrollListener() {
//   final scrollPosition = _scrollController.position;
//   final pixels = scrollPosition.pixels;
//   final maxScrollExtent = scrollPosition.maxScrollExtent;
//   final threshold = maxScrollExtent - 300;
//
//   // _print('FSCR:📜 Scroll listener - pixels: $pixels, maxScrollExtent: $maxScrollExtent, threshold: $threshold');
//
//   if (pixels >= threshold && !ref.read(feedPostsProvider).isLoadingMorePostsAtBottom && ref.read(feedPostsProvider).hasMorePosts) {
//     // _print('FSCR:📥 Triggering fetchMorePosts - reached scroll threshold');
//     ref.read(feedPostsProvider.notifier).fetchMorePosts();
//   } else {
//     // _print('FSCR:⏸️ Scroll threshold not met or conditions not satisfied');
//     // _print('FSCR:   - isLoadingMore: ${ref.read(feedPostsProvider).isLoadingMorePostsAtBottom}');
//     // _print('FSCR:   - hasMorePosts: ${ref.read(feedPostsProvider).hasMorePosts}');
//     // _print('FSCR:   - pixels >= threshold: ${pixels >= threshold}');
//   }
// }
//
// void _scrollDownForPost(MemoModelPost post) {
//   if (!_scrollController.hasClients) {
//     _print('FSCR:📜 _scrollDownForPost - scroll controller has no clients');
//     return;
//   }
//
//   // final feedState = ref.read(feedPostsProvider);
//   // final postIndex = feedState.posts.indexWhere((p) => p.id == post.id);
//   // _print('FSCR:📜 _scrollDownForPost - postId: ${post.id}, found at index: $postIndex');
//
//   // if (postIndex != -1) {
//   final targetPosition = _scrollController.offset + 120.0;
//   _print('FSCR:📜 _scrollDownForPost - current offset: ${_scrollController.offset}, target: $targetPosition');
//
//   final maxScrollExtent = _scrollController.position.maxScrollExtent;
//   final clampedPosition = targetPosition.clamp(_scrollController.position.minScrollExtent, maxScrollExtent);
//   _print('FSCR:📜 _scrollDownForPost - clamped position: $clampedPosition');
//
//   _scrollController.animateTo(clampedPosition, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
//   _print('FSCR:📜 _scrollDownForPost - scroll animation started');
//   // } else {
//   //   _print('FSCR:❌ _scrollDownForPost - post not found in current posts list');
//   // }
// }

// @override
// void dispose() {
//   _print('FSCR:♻️ FeedScreen dispose called');
//   // _scrollController.removeListener(_scrollListener);
//   _scrollController.dispose();
//   // _listViewFocusNode.dispose();
//   super.dispose();
// }

// Map<ShortcutActivator, Intent> _getKeyboardShortcuts() {
//   return <ShortcutActivator, Intent>{
//     const SingleActivator(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
//     const SingleActivator(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
//   };
// }
//
// void _handleScrollIntent(Intent intent, BuildContext context) {
//   // _print('FSCR:⌨️ Keyboard scroll intent: $intent');
//   if (!_scrollController.hasClients) {
//     // _print('FSCR:❌ Scroll controller has no clients');
//     return;
//   }
//
//   double scrollAmount = 0;
//   const double estimatedItemHeight = 300.0;
//
//   if (intent is ScrollUpIntent) {
//     scrollAmount = -estimatedItemHeight;
//     // _print('FSCR:⬆️ Scrolling up by $scrollAmount');
//   } else if (intent is ScrollDownIntent) {
//     scrollAmount = estimatedItemHeight;
//     // _print('FSCR:⬇️ Scrolling down by $scrollAmount');
//   }
//
//   if (scrollAmount != 0) {
//     final currentOffset = _scrollController.offset;
//     final targetOffset = currentOffset + scrollAmount;
//     final clampedOffset = targetOffset.clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent);
//
//     // _print('FSCR:📜 Animating scroll from $currentOffset to $clampedOffset');
//     _scrollController.animateTo(clampedOffset, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
//   }
// }
