import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/profile_data_notifier.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/widgets/profile/posts_categorizer.dart';

import '../providers/navigation_providers.dart';

final currentProfileIdProvider = Provider<String?>((ref) {
  final loggedInUser = ref.watch(userProvider);
  var watch = ref.watch(profileTargetIdProvider);
  return watch.isEmpty ? loggedInUser?.profileIdMemoBch : watch;
});

final profileDataNotifier = AsyncNotifierProvider<ProfileDataNotifier, ProfileData>(() => ProfileDataNotifier());

class ProfileData {
  final MemoModelCreator? creator;
  final List<MemoModelPost> posts;
  final PostsCategorizer categorizer;
  final bool fromCache;
  final bool postsLoaded;

  ProfileData({required this.creator, required this.posts, required this.categorizer, this.fromCache = false, this.postsLoaded = false});

  factory ProfileData.empty() {
    return ProfileData(creator: null, posts: [], categorizer: PostsCategorizer.empty(), fromCache: false, postsLoaded: false);
  }

  bool get isLoading => creator == null || !postsLoaded;
  bool get hasData => creator != null && postsLoaded;

  ProfileData copyWith({
    MemoModelCreator? creator,
    List<MemoModelPost>? posts,
    PostsCategorizer? categorizer,
    bool? fromCache,
    bool? postsLoaded,
  }) {
    return ProfileData(
      creator: creator ?? this.creator,
      posts: posts ?? this.posts,
      categorizer: categorizer ?? this.categorizer,
      fromCache: fromCache ?? this.fromCache,
      postsLoaded: postsLoaded ?? this.postsLoaded,
    );
  }
}
