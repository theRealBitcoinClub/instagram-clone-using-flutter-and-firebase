// // lib/providers/profile_providers.dart
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mahakka/memo/model/memo_model_creator.dart';
// import 'package:mahakka/memo/model/memo_model_post.dart';
// import 'package:mahakka/repositories/creator_repository.dart';
// import 'package:mahakka/repositories/post_repository.dart';
//
// // Provides the creator's data for the profile screen
// final creatorStateProvider = AsyncNotifierProvider.family<CreatorNotifier, MemoModelCreator?, String>(() => CreatorNotifier());
//
// class CreatorNotifier extends FamilyAsyncNotifier<MemoModelCreator?, String> {
//   @override
//   Future<MemoModelCreator?> build(String arg) async {
//     return ref.read(creatorRepositoryProvider).getCreator(arg);
//   }
//
//   // A public method to refresh the creator data
//   Future<void> refresh() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() => ref.read(creatorRepositoryProvider).getCreator(arg));
//   }
// }
//
// // Provides the stream of posts for a given creator ID
// final postsStreamProvider = StreamProvider.family<List<MemoModelPost>, String>((ref, creatorId) {
//   return ref.read(postRepositoryProvider).getPostsByCreatorId(creatorId);
// });
