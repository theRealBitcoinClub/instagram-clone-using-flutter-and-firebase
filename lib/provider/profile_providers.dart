// lib/providers/profile_providers.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/widgets/profile/posts_categorizer.dart';

// Provider for the current profile ID
final _currentProfileIdProvider = Provider<String?>((ref) {
  final loggedInUser = ref.watch(userProvider);
  return ref.watch(profileTargetIdProvider) ?? loggedInUser?.profileIdMemoBch;
});

// Combined provider that ensures posts are only loaded after creator is loaded
final profileDataProvider = AsyncNotifierProvider<ProfileDataNotifier, ProfileData>(() => ProfileDataNotifier());

class ProfileData {
  final MemoModelCreator? creator;
  final List<MemoModelPost> posts;
  final PostsCategorizer categorizer;
  final bool fromCache;
  final bool postsLoaded; // Track if posts are fully loaded
  // final DateTime? loadStartTime; // Track when loading started

  ProfileData({
    required this.creator,
    required this.posts,
    required this.categorizer,
    this.fromCache = false,
    this.postsLoaded = false,
    // this.loadStartTime,
  });

  bool get isLoading => creator == null || !postsLoaded;
  bool get hasData => creator != null && postsLoaded && posts.isNotEmpty;

  // Calculate minimum display time remaining
  // Duration get minDisplayTimeRemaining {
  //   if (loadStartTime == null) return Duration.zero;
  //   final elapsed = DateTime.now().difference(loadStartTime!);
  //   const minDisplayTime = Duration(seconds: 1);
  //   return elapsed < minDisplayTime ? minDisplayTime - elapsed : Duration.zero;
  // }

  // Helper method to create a copy with updated fields
  ProfileData copyWith({
    MemoModelCreator? creator,
    List<MemoModelPost>? posts,
    PostsCategorizer? categorizer,
    bool? fromCache,
    bool? postsLoaded,
    DateTime? loadStartTime,
  }) {
    return ProfileData(
      creator: creator ?? this.creator,
      posts: posts ?? this.posts,
      categorizer: categorizer ?? this.categorizer,
      fromCache: fromCache ?? this.fromCache,
      postsLoaded: postsLoaded ?? this.postsLoaded,
      // loadStartTime: loadStartTime ?? this.loadStartTime,
    );
  }
}

class ProfileDataNotifier extends AsyncNotifier<ProfileData> {
  Timer? _balanceRefreshTimer;
  Timer? _mahakkaBalanceRefreshTimer;
  Timer? _memoBalanceRefreshTimer;
  Duration _refreshBalanceInterval = Duration(seconds: kDebugMode ? 5 : 5);
  bool _isAutoRefreshRunning = false;
  DateTime? _lastRefreshTime;
  String? _lastProfileIdPostDataRequest;
  String? _lastProfileIdRefreshRequest;
  int? _lastTabIndex;
  bool _pendingRefresh = false;

  // Stream management for creator updates
  StreamSubscription<MemoModelCreator?>? _creatorSubscription;
  String? _currentWatchedCreatorId;

  // Timer for minimum display time
  // Timer? _minDisplayTimer;
  // Completer<void>? _minDisplayCompleter;

  @override
  Future<ProfileData> build() async {
    ref.onDispose(() {
      _cancelCreatorSubscription();
      _stopAllBalanceTimers();
      // _minDisplayTimer?.cancel();
    });

    final profileId = ref.watch(_currentProfileIdProvider);

    if (profileId == null || profileId.isEmpty) {
      _cancelCreatorSubscription();
      return ProfileData(creator: null, posts: [], categorizer: PostsCategorizer.empty());
    }

    // Set up creator update subscription for the current profile
    _setupCreatorSubscription(profileId);

    // Handle pending refresh from previous build
    if (_pendingRefresh) {
      _pendingRefresh = false;
      return await _loadProfileData(profileId, forceScrape: true);
    }

    // Always load fresh data when profileId changes
    if (_lastProfileIdPostDataRequest != profileId) {
      return await _loadProfileData(profileId, forceScrape: true);
    }

    // Check if we should use cached data (only if same profile and recent)
    final now = DateTime.now();
    final shouldUseCache = _lastRefreshTime != null && now.difference(_lastRefreshTime!) < Duration(minutes: 5) && state.value != null;

    if (shouldUseCache && state.value != null && state.value!.postsLoaded) {
      return state.value!;
    }

    return await _loadProfileData(profileId, forceScrape: true);
  }

  /// Sets up a stream subscription to listen for updates to the current creator
  void _setupCreatorSubscription(String profileId) {
    // Only set up if we're not already watching this creator
    if (_currentWatchedCreatorId == profileId) return;

    // Cancel previous subscription (if watching a different creator)
    _cancelCreatorSubscription();

    _currentWatchedCreatorId = profileId;
    final creatorRepo = ref.read(creatorRepositoryProvider);

    print("INFO: Setting up creator update stream for profile: $profileId");

    _creatorSubscription = creatorRepo.watchCreator(profileId).listen((updatedCreator) {
      _handleCreatorUpdate(updatedCreator);
    });
  }

  /// Handles creator updates from the stream
  void _handleCreatorUpdate(MemoModelCreator? updatedCreator) {
    if (updatedCreator != null && state.value != null) {
      final currentData = state.value!;

      print("INFO: Updating profile data with new creator data for: ${updatedCreator.id}");

      state = AsyncValue.data(currentData.copyWith(creator: updatedCreator));
    }
  }

  /// Cancels the current creator subscription
  void _cancelCreatorSubscription() {
    if (_creatorSubscription != null) {
      _creatorSubscription!.cancel();
      _creatorSubscription = null;
      print("INFO: Canceled creator update stream for profile: $_currentWatchedCreatorId");
    }
    _currentWatchedCreatorId = null;
  }

  Future<ProfileData> _loadProfileData(String profileId, {bool forceScrape = false}) async {
    _lastProfileIdPostDataRequest = profileId;
    _lastRefreshTime = DateTime.now();

    final loadStartTime = DateTime.now();

    try {
      // Load creator from repository
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: forceScrape);

      // Create initial data with creator but posts not loaded yet
      final initialData = ProfileData(
        creator: creator,
        posts: [],
        categorizer: PostsCategorizer.empty(),
        fromCache: !forceScrape,
        postsLoaded: false,
        // loadStartTime: loadStartTime,
      );

      // Update state immediately with creator data (posts still loading)
      // state = AsyncValue.data(initialData);

      // Load posts
      final posts = await _loadPosts(profileId);

      // Categorize posts
      final categorizer = PostsCategorizer.fromPosts(posts);

      // Create complete data
      final completeData = ProfileData(
        creator: creator,
        posts: posts,
        categorizer: categorizer,
        fromCache: !forceScrape,
        postsLoaded: true,
        // loadStartTime: loadStartTime,
      );

      // Ensure minimum display time
      // await _ensureMinDisplayTime(loadStartTime);

      return completeData;
    } catch (e) {
      // If we have a previous state, return it as fallback
      if (state.value != null) {
        return state.value!.copyWith(loadStartTime: loadStartTime);
      }
      rethrow;
    }
  }

  /// Ensures data is displayed for at least 1 second to avoid flickering
  // Future<void> _ensureMinDisplayTime(DateTime loadStartTime) async {
  //   final elapsed = DateTime.now().difference(loadStartTime);
  //   const minDisplayTime = Duration(seconds: 3);
  //
  //   if (elapsed < minDisplayTime) {
  //     final remaining = minDisplayTime - elapsed;
  //     _minDisplayCompleter = Completer<void>();
  //     _minDisplayTimer = Timer(remaining, () {
  //       _minDisplayCompleter?.complete();
  //       _minDisplayCompleter = null;
  //     });
  //     await _minDisplayCompleter?.future;
  //   }
  // }

  Future<List<MemoModelPost>> _loadPosts(String profileId) async {
    try {
      final postRepository = ref.read(postRepositoryProvider);
      final postsStream = postRepository.getPostsByCreatorId(profileId);

      // Convert stream to future for initial load with timeout
      return await postsStream.first.timeout(Duration(seconds: 15));
    } catch (e) {
      print('Error loading posts: $e');
      return [];
    }
  }

  Future<void> refreshProfile({bool forceScrape = false}) async {
    // Schedule the refresh to happen after the current build phase
    Future.microtask(() async {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        final profileId = ref.read(_currentProfileIdProvider);
        if (profileId == null || profileId.isEmpty) {
          return ProfileData(creator: null, posts: [], categorizer: PostsCategorizer.empty());
        }

        return await _loadProfileData(profileId, forceScrape: forceScrape);
      });
    });
  }

  Future<void> refreshCreatorCache(String creatorId) async {
    final creatorRepository = ref.read(creatorRepositoryProvider);

    // Schedule the operation to happen after build
    Future.microtask(() async {
      await creatorRepository.refreshCreatorCache(
        creatorId,
        hasUpdatedCallback: () {
          print("refreshCreatorCache fresh scrape success for creatorId $creatorId");
        },
        nothingChangedCallback: () {
          print("refreshCreatorCache no fresh data available for creatorId $creatorId");
        },
        scrapeFailedCallback: () {
          print("refreshCreatorCache scrape failed for creatorId $creatorId");
        },
      );
    });
  }

  void refreshProfileDataAndStartBalanceTimer(int currentTabIndex, String profileId, bool isOwnProfile) {
    // Schedule the operation to happen after build
    Future.microtask(() {
      if (currentTabIndex == 2) {
        if (_lastTabIndex != currentTabIndex || _lastProfileIdRefreshRequest != profileId) {
          refreshUserRegisteredFlag();
          refreshBalances();
          refreshCreatorCache(profileId);
        }
        // if (isOwnProfile) {
        startAutoRefreshBalanceProfile();
        // }
        // else {
        //   stopAutoRefreshBalanceProfile();
        // }
        // Set pending refresh flag for next build
        _pendingRefresh = true;
        _lastProfileIdRefreshRequest = profileId;
      } else {
        stopAutoRefreshBalanceProfile();
      }
      _lastTabIndex = currentTabIndex;
    });
  }

  Future<void> refreshUserRegisteredFlag() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      var creatorRepository = ref.read(creatorRepositoryProvider);
      var memoModelCreator = await creatorRepository.getCreator(profileId);
      final creator = memoModelCreator;
      if (creator != null && !creator.hasRegisteredAsUser) {
        await creator.refreshUserHasRegistered(ref, creatorRepository);
      }
    }
  }

  Future<void> refreshBalances() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      var creatorRepository = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepository.getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalances(ref, creatorRepository);
      }
    }
  }

  Future<void> refreshMahakkaBalance() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null && creator.hasRegisteredAsUser) {
        await creator.refreshBalanceMahakka(ref);
      }
    }
  }

  Future<void> refreshMemoBalance() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalanceMemo(ref);
      }
    }
  }

  bool isAutoRefreshRunning() {
    return _isAutoRefreshRunning;
  }

  void stopAutoRefreshBalanceProfile() {
    if (!_isAutoRefreshRunning) return;
    _stopAllBalanceTimers(stopProfileRefresh: true);
    _isAutoRefreshRunning = false;
  }

  void startAutoRefreshBalanceProfile() {
    if (_isAutoRefreshRunning) return;

    _stopAllBalanceTimers(stopProfileRefresh: true);
    _isAutoRefreshRunning = true;
    _startBalanceRefreshTimerProfile();
  }

  void startAutoRefreshMahakkaBalanceQrDialog() {
    if (!_isAutoRefreshRunning) {
      _stopAllBalanceTimers();
      _startMahakkaBalanceRefreshTimerQrDialog();
    }
  }

  void startAutoRefreshMemoBalanceQrDialog() {
    if (!_isAutoRefreshRunning) {
      _stopAllBalanceTimers();
      _startMemoBalanceRefreshTimerQrDialog();
    }
  }

  void _startBalanceRefreshTimerProfile() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshBalancesPeriodicallyOnProfile();
    });
  }

  void _startMahakkaBalanceRefreshTimerQrDialog() {
    _mahakkaBalanceRefreshTimer?.cancel();
    _mahakkaBalanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshMahakkaBalancePeriodicallyOnQrDialog();
    });
  }

  void _startMemoBalanceRefreshTimerQrDialog() {
    _memoBalanceRefreshTimer?.cancel();
    _memoBalanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshMemoBalancePeriodicallyOnQrDialog();
    });
  }

  void _stopAllBalanceTimers({bool stopProfileRefresh = false}) {
    if (stopProfileRefresh) {
      _balanceRefreshTimer?.cancel();
      _balanceRefreshTimer = null;
    }

    _mahakkaBalanceRefreshTimer?.cancel();
    _memoBalanceRefreshTimer?.cancel();

    _mahakkaBalanceRefreshTimer = null;
    _memoBalanceRefreshTimer = null;
  }

  Future<void> _refreshBalancesPeriodicallyOnProfile() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId == null || profileId.isEmpty || state.isLoading) {
      return;
    }

    try {
      final currentData = state.value;
      if (currentData != null && currentData.creator != null) {
        Future.microtask(() async {
          await refreshBalances();
        });
      }
    } catch (e) {
      print('Periodic balance refresh failed: $e');
    }
  }

  Future<void> _refreshMahakkaBalancePeriodicallyOnQrDialog() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId == null || profileId.isEmpty || state.isLoading) {
      return;
    }

    try {
      final currentData = state.value;
      if (currentData != null && currentData.creator != null && currentData.creator!.hasRegisteredAsUser) {
        Future.microtask(() async {
          await refreshMahakkaBalance();
        });
      }
    } catch (e) {
      print('Periodic Mahakka balance refresh failed: $e');
    }
  }

  Future<void> _refreshMemoBalancePeriodicallyOnQrDialog() async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId == null || profileId.isEmpty || state.isLoading) {
      return;
    }

    try {
      final currentData = state.value;
      if (currentData != null && currentData.creator != null) {
        Future.microtask(() async {
          await refreshMemoBalance();
        });
      }
    } catch (e) {
      print('Periodic Memo balance refresh failed: $e');
    }
  }
}

// Keep postsStreamProvider for other parts of the app that need the stream
final postsStreamProvider = StreamProvider<List<MemoModelPost>>((ref) {
  final creatorId = ref.watch(_currentProfileIdProvider);
  if (creatorId == null || creatorId.isEmpty) {
    return const Stream.empty();
  }
  return ref.read(postRepositoryProvider).getPostsByCreatorId(creatorId);
});
