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

class ProfileDataNotifier extends AsyncNotifier<ProfileData> {
  String? _lastProfileId;
  String? _lastProfileIdOnLoad;
  StreamSubscription<MemoModelCreator?>? _creatorSubscription;
  String? _currentWatchedCreatorId;
  final bool _debugMode = kDebugMode;

  @override
  Future<ProfileData> build() async {
    if (_debugMode) print("🔄 PDN: ProfileDataNotifier build() called");

    ref.onDispose(() {
      if (_debugMode) print("🔴 PDN: ProfileDataNotifier disposed");
      _cancelCreatorSubscription();
      ref.read(profileBalanceProvider).stopBalanceTimers();
    });

    state = AsyncData(ProfileData.empty());

    final profileId = ref.watch(currentProfileIdProvider);
    if (_debugMode) print("👤 PDN: Current profileId: $profileId");

    if (profileId == null || profileId.isEmpty) {
      if (_debugMode) print("❌ PDN: No profileId available");
      _cancelCreatorSubscription();
      return ProfileData.empty();
    }

    // Only refresh POSTS if profileId changed
    if (_lastProfileId != profileId) {
      if (_debugMode) print("🔄 PDN: ProfileId changed from $_lastProfileId to $profileId, loading fresh data");
      _lastProfileId = profileId;
      _setupCreatorSubscription(profileId);
      return await _loadProfileData(profileId);
    }

    // Same profile - maintain creator subscription but keep existing posts
    if (_currentWatchedCreatorId != profileId) {
      if (_debugMode) print("🔄 PDN: Same profile, setting up creator subscription");
      _setupCreatorSubscription(profileId);
    } else {
      if (_debugMode) print("ℹ️ PDN: Same profile and subscription active, keeping existing posts");
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

    if (_debugMode) print("🔄 PDN: Creator subscription started for: $profileId");
  }

  void _handleCreatorUpdate(MemoModelCreator? updatedCreator) {
    if (_debugMode) print("🔄 PDN: Creator update received via subscription");

    // This handles SettingsWidget updates - only update creator, keep posts unchanged
    if (updatedCreator != null && state.value != null) {
      final currentData = state.value!;

      Future.microtask(() {
        try {
          // Update only the creator fields, preserve existing posts and categorizer
          state = AsyncValue.data(currentData.copyWith(creator: updatedCreator));
          if (_debugMode) print("✅ PDN: Creator updated via subscription, posts preserved");
        } catch (e) {
          if (_debugMode) print("❌ PDN: Creator update failed: $e");
        }
      });
    }
  }

  void _cancelCreatorSubscription() {
    _creatorSubscription?.cancel();
    _creatorSubscription = null;
    _currentWatchedCreatorId = null;
    if (_debugMode) print("🔴 PDN: Creator subscription cancelled");
  }

  Future<ProfileData> _loadProfileData(String profileId) async {
    if (_debugMode) print("📥 PDN: Loading profile data for: $profileId");

    final postCache = ref.read(profilePostCacheProvider);
    final creatorRepo = ref.read(creatorRepositoryProvider);

    // 1. Load creator data
    final creator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: false);
    if (_debugMode) print("👤 PDN: Creator data loaded: ${creator != null}");

    // 2. Load posts using the new list implementation
    final posts = await _fetchPosts(profileId);
    if (_debugMode) print("📝 PDN: Posts loaded: ${posts.length}");

    final categorizer = PostsCategorizer.fromPosts(posts);
    final profileData = ProfileData(
      creator: creator,
      posts: posts,
      categorizer: categorizer,
      fromCache: false, // This will be determined by the PostService
      postsLoaded: true,
    );

    if (_debugMode) print("✅ PDN: Profile data loaded successfully");
    return profileData;
  }

  Future<List<MemoModelPost>> _fetchPosts(String profileId) async {
    if (_debugMode) print("📝 PDN: Fetching posts for profile: $profileId");

    try {
      // Use the new list-based implementation
      final posts = await ref.read(postServiceProfileProvider).getPostsByCreatorIdList(profileId, ref);
      if (_debugMode) print("✅ PDN: Successfully fetched ${posts.length} posts");
      return posts;
    } catch (e) {
      if (_debugMode) print("❌ PDN: Error fetching posts: $e");

      // Fallback to cache only
      final postCache = ref.read(profilePostCacheProvider);
      final cachedPosts = await postCache.getCachedProfilePosts(profileId);
      if (_debugMode) print(cachedPosts.isNotEmpty ? "📚 PDN: Using cached posts as fallback" : "❌ PDN: No posts available");
      return cachedPosts;
    }
  }

  void refreshCreatorDataOnProfileLoad(int currentTabIndex, String profileId, bool isOwnProfile, BuildContext ctx) {
    if (_debugMode) print("🔄 PDN: refreshCreatorDataOnProfileLoad called");

    ctx.afterBuild(refreshUI: false, () {
      if (currentTabIndex == 2) {
        if (ref.read(profileTargetIdProvider) != _lastProfileIdOnLoad) {
          if (_debugMode) print("🔄 PDN: Refreshing creator cache and balances");
          _lastProfileIdOnLoad = profileId;
          ref.read(creatorRepositoryProvider).refreshCreatorCache(profileId);
          refreshUserRegisteredFlag();
          ref.read(profileBalanceProvider).refreshBalances();
        }
      }
    });
  }

  Future<void> refreshUserRegisteredFlag() async {
    if (_debugMode) print("🔄 PDN: Refreshing user registered flag");

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

  void notifyStateUpdate(BuildContext ctx) {
    if (_debugMode) print("🔄 PDN: Manual state update notification");

    if (state.value != null && ctx.mounted) {
      state = AsyncValue.data(state.value!);
    }
  }
}

// import 'dart:async';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mahakka/app_utils.dart';
// import 'package:mahakka/memo/model/memo_model_creator.dart';
// import 'package:mahakka/memo/model/memo_model_post.dart';
// import 'package:mahakka/provider/profile_balance_provider.dart';
// import 'package:mahakka/provider/profile_data_model_provider.dart';
// import 'package:mahakka/repositories/creator_repository.dart';
// import 'package:mahakka/repositories/post_repository.dart';
// import 'package:mahakka/repositories/profile_post_cache.dart';
// import 'package:mahakka/widgets/profile/posts_categorizer.dart';
//
// import '../providers/navigation_providers.dart';
//
// class ProfileDataNotifier extends AsyncNotifier<ProfileData> {
//   String? _lastProfileId;
//   String? _lastProfileIdOnLoad;
//   StreamSubscription<MemoModelCreator?>? _creatorSubscription;
//   String? _currentWatchedCreatorId;
//
//   @override
//   Future<ProfileData> build() async {
//     ref.onDispose(() {
//       _cancelCreatorSubscription();
//       ref.read(profileBalanceProvider).stopBalanceTimers();
//     });
//
//     state = AsyncData(ProfileData.empty());
//
//     final profileId = ref.watch(currentProfileIdProvider);
//
//     if (profileId == null || profileId.isEmpty) {
//       _cancelCreatorSubscription();
//       return ProfileData.empty();
//     }
//
//     // Only refresh POSTS if profileId changed
//     if (_lastProfileId != profileId) {
//       _lastProfileId = profileId;
//       _setupCreatorSubscription(profileId);
//       return await _loadProfileData(profileId);
//     }
//
//     // Same profile - maintain creator subscription but keep existing posts
//     if (_currentWatchedCreatorId != profileId) {
//       _setupCreatorSubscription(profileId);
//     }
//
//     return state.valueOrNull ?? ProfileData.empty();
//   }
//
//   void _setupCreatorSubscription(String profileId) {
//     if (_currentWatchedCreatorId == profileId) return;
//     _cancelCreatorSubscription();
//
//     _currentWatchedCreatorId = profileId;
//     final creatorRepo = ref.read(creatorRepositoryProvider);
//
//     _creatorSubscription = creatorRepo.watchCreator(profileId).listen((updatedCreator) {
//       _handleCreatorUpdate(updatedCreator);
//     });
//
//     if (kDebugMode) print("🔄 Creator subscription started for: $profileId");
//   }
//
//   void _handleCreatorUpdate(MemoModelCreator? updatedCreator) {
//     // This handles SettingsWidget updates - only update creator, keep posts unchanged
//     if (updatedCreator != null && state.value != null) {
//       final currentData = state.value!;
//
//       Future.microtask(() {
//         try {
//           // Update only the creator fields, preserve existing posts and categorizer
//           state = AsyncValue.data(currentData.copyWith(creator: updatedCreator));
//           if (kDebugMode) print("✅ Creator updated via subscription");
//         } catch (e) {
//           if (kDebugMode) print("Creator update failed: $e");
//         }
//       });
//     }
//   }
//
//   void _cancelCreatorSubscription() {
//     _creatorSubscription?.cancel();
//     _creatorSubscription = null;
//     _currentWatchedCreatorId = null;
//     if (kDebugMode) print("🔴 Creator subscription cancelled");
//   }
//
//   Future<ProfileData> _loadProfileData(String profileId) async {
//     final postCache = ref.read(profilePostCacheProvider);
//     final creatorRepo = ref.read(creatorRepositoryProvider);
//
//     // 1. Try cache first for instant display
//     final creator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: false);
//     final cachedPosts = await postCache.getCachedProfilePosts(profileId);
//
//     if (cachedPosts.isNotEmpty) {
//       final categorizer = PostsCategorizer.fromPosts(cachedPosts);
//       final cachedData = ProfileData(creator: creator, posts: cachedPosts, categorizer: categorizer, fromCache: true, postsLoaded: true);
//
//       // Start background refresh for updated data
//       _refreshInBackground(profileId, creator);
//       return cachedData;
//     }
//
//     // 2. No complete cache available - fetch fresh data
//     return await _fetchFreshPostData(profileId, creator);
//   }
//
//   Future<ProfileData> _fetchFreshPostData(String profileId, creator) async {
//     final postCache = ref.read(profilePostCacheProvider);
//     final creatorRepo = ref.read(creatorRepositoryProvider);
//     try {
//       final posts = await _fetchPosts(profileId);
//       print("📝 Posts fetched from Firebase for: $profileId length: ${posts.length}");
//
//       final categorizer = PostsCategorizer.fromPosts(posts);
//       final profileData = ProfileData(creator: creator, posts: posts, categorizer: categorizer, fromCache: false, postsLoaded: true);
//
//       // Cache the posts in PostCacheRepository
//       await postCache.cacheProfilePosts(profileId, posts);
//       //TODO WHY CACHE PROFILE POSTS HERE THAT HAVE BEEN LOADED FROM CACHE??? ONE PLACE AFTER FIREBASE FETCH SHALL BE FOR CACHING
//       if (kDebugMode) print("✅ Fresh profile data loaded for: $profileId");
//       return profileData;
//     } catch (e) {
//       if (kDebugMode) print("Error fetching fresh data: $e");
//       // Fallback to any available cache
//       final cachedCreator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: false);
//       final cachedPosts = await postCache.getCachedProfilePosts(profileId);
//
//       final categorizer = PostsCategorizer.fromPosts(cachedPosts);
//       return ProfileData(creator: cachedCreator, posts: cachedPosts, categorizer: categorizer, fromCache: true, postsLoaded: true);
//     }
//   }
//
//   Future<List<MemoModelPost>> _fetchPosts(String profileId) async {
//     final postCacheProfile = ref.read(profilePostCacheProvider);
//
//     try {
//       // Single Firebase read - no persistent listener for posts
//       final postsStream = ref.read(postServiceProfileProvider).getPostsByCreatorIdStream(profileId, ref);
//       final posts = await postsStream.first.timeout(Duration(seconds: 20));
//       if (kDebugMode) print("📝 Posts fetched from Firebase for: $profileId");
//       return posts;
//     } catch (e) {
//       if (kDebugMode) print("Error fetching posts: $e");
//       // Fallback to cache
//       final cachedPosts = await postCacheProfile.getCachedProfilePosts(profileId);
//       if (kDebugMode) print(cachedPosts.isNotEmpty ? "📝 Using cached posts" : "❌ No posts available");
//       return cachedPosts;
//     }
//   }
//
//   void _refreshInBackground(String profileId, creator) {
//     // Fire and forget background refresh
//     Future.microtask(() async {
//       try {
//         final freshData = await _fetchFreshPostData(profileId, creator);
//
//         // Only update state if we're still on the same profile
//         if (ref.read(currentProfileIdProvider) == profileId) {
//           state = AsyncValue.data(freshData);
//           if (kDebugMode) print("✅ Background refresh completed for: $profileId");
//         }
//       } catch (e) {
//         if (kDebugMode) print("Background refresh failed: $e");
//         // Silent fail - we already have cached data
//       }
//     });
//   }
//
//   void refreshCreatorDataOnProfileLoad(int currentTabIndex, String profileId, bool isOwnProfile, BuildContext ctx) {
//     ctx.afterBuild(refreshUI: false, () {
//       if (currentTabIndex == 2) {
//         if (ref.read(profileTargetIdProvider) != _lastProfileIdOnLoad) {
//           _lastProfileIdOnLoad = profileId;
//           ref.read(creatorRepositoryProvider).refreshCreatorCache(profileId);
//           refreshUserRegisteredFlag();
//           ref.read(profileBalanceProvider).refreshBalances();
//         }
//       }
//     });
//   }
//
//   Future<void> refreshUserRegisteredFlag() async {
//     final profileId = ref.read(currentProfileIdProvider);
//     if (profileId != null && profileId.isNotEmpty) {
//       var creatorRepository = ref.read(creatorRepositoryProvider);
//       var memoModelCreator = await creatorRepository.getCreator(profileId);
//       final creator = memoModelCreator;
//       if (creator != null && !creator.hasRegisteredAsUserFixed) {
//         await creator.refreshUserHasRegistered(ref, creatorRepository);
//       }
//     }
//   }
//
//   void notifyStateUpdate(BuildContext ctx) {
//     if (state.value != null && ctx.mounted) {
//       state = AsyncValue.data(state.value!);
//     }
//   }
// }
