import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/profile_balance_provider.dart';
import 'package:mahakka/provider/profile_data_model_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/repositories/profile_post_cache.dart';
import 'package:mahakka/widgets/profile/posts_categorizer.dart';

import '../providers/navigation_providers.dart';
import '../providers/token_limits_provider.dart';

class ProfileDataNotifier extends AsyncNotifier<ProfileData> {
  String? _lastProfileId;
  String? _lastProfileIdOnLoad;
  int? _lastProfileLimit;
  StreamSubscription<MemoModelCreator?>? _creatorSubscription;
  String? _currentWatchedCreatorId;
  final bool _debugMode = kDebugMode;

  @override
  Future<ProfileData> build() async {
    _print("🔄 PDN: ProfileDataNotifier build() called");

    // Watch the profileLimitProvider to ensure it's active and reactive
    final profileLimit = ref.watch(profileLimitProvider);
    _print("📊 PDN: Current profile limit: $profileLimit");

    ref.onDispose(() {
      _print("🔴 PDN: ProfileDataNotifier disposed");
      _cancelCreatorSubscription();
      // Future.microtask(() {
      //   ref.read(profileBalanceProvider).stopBalanceTimers();
      // });
    });

    state = AsyncData(ProfileData.empty());

    final profileId = ref.watch(currentProfileIdProvider);
    _print("👤 PDN: Current profileId: $profileId");

    if (profileId == null || profileId.isEmpty) {
      _print("❌ PDN: No profileId available");
      _cancelCreatorSubscription();
      return ProfileData.empty();
    }

    // Only refresh POSTS if profileId OR profileLimit changed
    if (_lastProfileId != profileId || _lastProfileLimit != profileLimit) {
      _print("🔄 PDN: ProfileId or limit changed from $_lastProfileId/$_lastProfileLimit to $profileId/$profileLimit, loading fresh data");
      _lastProfileId = profileId;
      _lastProfileLimit = profileLimit;
      _setupCreatorSubscription(profileId);
      return await _loadProfileData(profileId, profileLimit);
    }

    // Same profile and limit - maintain creator subscription but keep existing posts
    if (_currentWatchedCreatorId != profileId) {
      _print("🔄 PDN: Same profile, setting up creator subscription");
      _setupCreatorSubscription(profileId);
    } else {
      _print("ℹ️ PDN: Same profile and subscription active, keeping existing posts");
    }

    return state.valueOrNull ?? ProfileData.empty();
  }

  void _setupCreatorSubscription(String profileId) {
    if (_currentWatchedCreatorId == profileId) return;
    _cancelCreatorSubscription();

    _currentWatchedCreatorId = profileId;
    final creatorRepo = ref.read(creatorRepositoryProvider);

    _creatorSubscription = creatorRepo.watchCreator(profileId).listen((updatedCreator) {
      _handleCreatorUpdate(updatedCreator);
    });

    _print("🔄 PDN: Creator subscription started for: $profileId");
  }

  void _handleCreatorUpdate(MemoModelCreator? updatedCreator) {
    _print("🔄 PDN: Creator update received via subscription");

    // This handles SettingsWidget updates - only update creator, keep posts unchanged
    if (updatedCreator != null && state.value != null) {
      final currentData = state.value!;

      Future.microtask(() {
        try {
          // Update only the creator fields, preserve existing posts and categorizer
          state = AsyncValue.data(currentData.copyWith(creator: updatedCreator));
          _print("✅ PDN: Creator updated via subscription, posts preserved");
        } catch (e) {
          _print("❌ PDN: Creator update failed: $e");
        }
      });
    }
  }

  void _cancelCreatorSubscription() {
    _creatorSubscription?.cancel();
    _creatorSubscription = null;
    _currentWatchedCreatorId = null;
    _print("🔴 PDN: Creator subscription cancelled");
  }

  Future<ProfileData> _loadProfileData(String profileId, int limit) async {
    _print("📥 PDN: Loading profile data for: $profileId");

    final postCache = ref.read(profilePostCacheProvider);
    final creatorRepo = ref.read(creatorRepositoryProvider);

    // 1. Load creator data
    final creator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: false);
    _print("👤 PDN: Creator data loaded: ${creator != null}");

    // 2. Load posts using the new list implementation
    final posts = await _fetchPosts(profileId, limit);
    _print("📝 PDN: Posts loaded: ${posts.length}");

    final categorizer = PostsCategorizer.fromPosts(posts);
    final profileData = ProfileData(
      creator: creator,
      posts: posts,
      categorizer: categorizer,
      fromCache: false, // This will be determined by the PostService
      postsLoaded: true,
    );

    _print("✅ PDN: Profile data loaded successfully");
    return profileData;
  }

  Future<List<MemoModelPost>> _fetchPosts(String profileId, limit) async {
    _print("📝 PDN: Fetching posts for profile: $profileId");

    try {
      // Use the new list-based implementation
      final posts = await ref.read(postServiceProfileProvider).getPostsByCreatorIdList(profileId, ref, limit);
      _print("✅ PDN: Successfully fetched ${posts.length} posts");
      return posts;
    } catch (e) {
      _print("❌ PDN: Error fetching posts: $e");

      // Fallback to cache only
      final postCache = ref.read(profilePostCacheProvider);
      final cachedPosts = await postCache.getCachedProfilePosts(profileId, limit);
      if (_debugMode) print(cachedPosts.isNotEmpty ? "📚 PDN: Using cached posts as fallback" : "❌ PDN: No posts available");
      return cachedPosts;
    }
  }

  void refreshCreatorDataOnProfileLoad(int currentTabIndex, String profileId, bool isOwnProfile, BuildContext ctx) {
    _print("🔄 PDN: refreshCreatorDataOnProfileLoad called");

    ctx.afterBuild(refreshUI: false, () {
      if (currentTabIndex == 2) {
        if (ref.read(profileTargetIdProvider) != _lastProfileIdOnLoad) {
          _print("🔄 PDN: Refreshing creator cache and balances");
          _lastProfileIdOnLoad = profileId;
          ref.read(creatorRepositoryProvider).refreshCreatorCache(profileId);
          refreshUserRegisteredFlag();
          ref.read(profileBalanceProvider).refreshBalances(ctx);
        }
      }
    });
  }

  Future<void> refreshUserRegisteredFlag() async {
    _print("🔄 PDN: Refreshing user registered flag");

    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      var creatorRepository = ref.read(creatorRepositoryProvider);
      var memoModelCreator = await creatorRepository.getCreator(profileId);
      final creator = memoModelCreator;
      if (creator != null && !creator.hasRegisteredAsUserFixed) {
        await creator.refreshUserHasRegistered(ref, creatorRepository);
      }
    }
  }

  void notifyStateUpdateCreator(BuildContext ctx, {MemoModelCreator? c}) async {
    String pId = ref.read(currentProfileIdProvider)!;
    _print("🔄 PDN: Manual state update notification");
    _print("🔄 PDN: Manual state update notification watchedId $_currentWatchedCreatorId");
    _print("🔄 PDN: Manual state update notification targetId $pId");

    MemoModelCreator? creator = c ?? await ref.read(creatorRepositoryProvider).getCreator(pId);
    if (state.value != null && creator != null && ctx.mounted) {
      state = AsyncValue.data(state.value!.copyWith(creator: creator));
    }
  }

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}
