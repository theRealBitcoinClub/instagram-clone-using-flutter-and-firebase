// lib/providers/profile_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/navigation_providers.dart'; // Import the source of truth
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/repositories/post_repository.dart';

// An internal provider that provides the current profile ID to watch
final _currentProfileIdProvider = Provider<String?>((ref) {
  final loggedInUser = ref.watch(userProvider);
  return ref.watch(profileTargetIdProvider) ?? loggedInUser?.profileIdMemoBch;
});

// Provides the creator's data for the profile screen, automatically re-fetching
// when the profile ID changes.
final creatorStateProvider = AsyncNotifierProvider<CreatorNotifier, MemoModelCreator?>(() => CreatorNotifier());

class CreatorNotifier extends AsyncNotifier<MemoModelCreator?> {
  @override
  Future<MemoModelCreator?> build() async {
    final creatorId = ref.watch(_currentProfileIdProvider);
    if (creatorId == null || creatorId.isEmpty) {
      // Return null or throw a specific error if no ID is available
      return null;
    }
    return ref.read(creatorRepositoryProvider).getCreator(creatorId);
  }

  // A public method to refresh the creator data
  Future<void> refresh() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId != null && creatorId.isNotEmpty) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => ref.read(creatorRepositoryProvider).getCreator(creatorId));
    }
  }
}

// Provides the stream of posts for the currently selected creator ID
final postsStreamProvider = StreamProvider<List<MemoModelPost>>((ref) {
  final creatorId = ref.watch(_currentProfileIdProvider);
  if (creatorId == null || creatorId.isEmpty) {
    return const Stream.empty();
  }
  return ref.read(postRepositoryProvider).getPostsByCreatorId(creatorId);
});
