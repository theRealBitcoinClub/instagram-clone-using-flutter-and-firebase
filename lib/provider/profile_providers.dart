import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/widgets/profile/posts_categorizer.dart';

import '../providers/navigation_providers.dart';

class ProfileDataCache {
  static final ProfileDataCache _instance = ProfileDataCache._internal();
  factory ProfileDataCache() => _instance;
  ProfileDataCache._internal();

  final _cache = <String, ProfileData>{};
  final _accessOrder = <String>[];
  static const int _maxSize = 100;

  ProfileData? get(String profileId) {
    if (_cache.containsKey(profileId)) {
      _accessOrder.remove(profileId);
      _accessOrder.add(profileId);
      return _cache[profileId];
    }
    return null;
  }

  void put(String profileId, ProfileData data) {
    if (_cache.length >= _maxSize && !_cache.containsKey(profileId)) {
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }

    _cache[profileId] = data;

    if (_accessOrder.contains(profileId)) {
      _accessOrder.remove(profileId);
    }
    _accessOrder.add(profileId);

    if (_cache.length > _maxSize * 2) {
      _evictExcess();
    }
  }

  void _evictExcess() {
    while (_cache.length > _maxSize) {
      final lruKey = _accessOrder.removeAt(0);
      _cache.remove(lruKey);
    }
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  void remove(String profileId) {
    _cache.remove(profileId);
    _accessOrder.remove(profileId);
  }

  int get size => _cache.length;
}

final _currentProfileIdProvider = Provider<String?>((ref) {
  final loggedInUser = ref.watch(userProvider);
  var watch = ref.watch(profileTargetIdProvider);
  return watch.isEmpty ? loggedInUser?.profileIdMemoBch : watch;
});

final profileDataProvider = AsyncNotifierProvider<ProfileDataNotifier, ProfileData>(() => ProfileDataNotifier());

class ProfileData {
  final MemoModelCreator? creator;
  final List<MemoModelPost> posts;
  final PostsCategorizer categorizer;
  final bool fromCache;
  final bool postsLoaded;

  ProfileData({required this.creator, required this.posts, required this.categorizer, this.fromCache = false, this.postsLoaded = false});

  bool get isLoading => creator == null || !postsLoaded;

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

class ProfileDataNotifier extends AsyncNotifier<ProfileData> {
  Timer? _balanceRefreshTimer;
  Duration _refreshBalanceInterval = Duration(seconds: kDebugMode ? 5 : 5);
  DateTime? _lastRefreshTime;
  String? _lastProfileIdPostDataRequest;
  String? _lastProfileIdRefreshRequest;
  int? _lastTabIndex;
  bool _forceRefresh = false;

  bool _isQrDialogOpen = false;
  bool _isQrCashtokenMode = false;
  Timer? _qrDialogRefreshTimer;
  final Duration _qrRefreshInterval = Duration(seconds: kDebugMode ? 3 : 3);

  StreamSubscription<MemoModelCreator?>? _creatorSubscription;
  String? _currentWatchedCreatorId;

  final ProfileDataCache _cache = ProfileDataCache();

  @override
  Future<ProfileData> build() async {
    ref.onDispose(() {
      _cancelCreatorSubscription();
      _stopAllTimers();
    });

    final profileId = ref.watch(_currentProfileIdProvider);

    if (profileId == null || profileId.isEmpty) {
      _cancelCreatorSubscription();
      return ProfileData(creator: null, posts: [], categorizer: PostsCategorizer.empty(), postsLoaded: false, fromCache: false);
    }

    final cachedData = _cache.get(profileId);
    final now = DateTime.now();
    final isCacheValid = cachedData != null && _lastRefreshTime != null && now.difference(_lastRefreshTime!) < Duration(minutes: 18);

    if (isCacheValid && cachedData!.postsLoaded) {
      return cachedData.copyWith(fromCache: true);
    }

    final creatorRepo = ref.read(creatorRepositoryProvider);
    final creator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: false);

    final initialData = ProfileData(creator: creator, posts: [], categorizer: PostsCategorizer.empty(), fromCache: false, postsLoaded: false);

    state = AsyncData(initialData);

    _setupCreatorSubscription(profileId);

    return await _loadProfileData(profileId, forceScrape: true);
  }

  void _setupCreatorSubscription(String profileId) {
    if (_currentWatchedCreatorId == profileId) return;

    _cancelCreatorSubscription();

    _currentWatchedCreatorId = profileId;
    final creatorRepo = ref.read(creatorRepositoryProvider);

    _creatorSubscription = creatorRepo.watchCreator(profileId).listen((updatedCreator) {
      _handleCreatorUpdate(updatedCreator);
    });
  }

  void _handleCreatorUpdate(MemoModelCreator? updatedCreator) {
    if (updatedCreator != null && state.value != null) {
      final currentData = state.value!;

      Future.microtask(() {
        try {
          state = AsyncValue.data(currentData.copyWith(creator: updatedCreator));
        } catch (e) {
          print("Profile data state update failed (safe during navigation): $e");
        }
      });
    }
  }

  void _cancelCreatorSubscription() {
    if (_creatorSubscription != null) {
      _creatorSubscription!.cancel();
      _creatorSubscription = null;
    }
    _currentWatchedCreatorId = null;
  }

  Future<ProfileData> _loadProfileData(String profileId, {bool forceScrape = false}) async {
    _lastProfileIdPostDataRequest = profileId;
    _lastRefreshTime = DateTime.now();

    try {
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepo.getCreator(profileId, saveToFirebase: false, forceScrape: forceScrape);

      final posts = await _loadPosts(profileId);

      final categorizer = PostsCategorizer.fromPosts(posts);

      final completeData = ProfileData(creator: creator, posts: posts, categorizer: categorizer, fromCache: !forceScrape, postsLoaded: true);

      _cache.put(profileId, completeData);

      return completeData;
    } catch (e) {
      final cachedData = _cache.get(profileId);
      if (cachedData != null) {
        return cachedData.copyWith(fromCache: true);
      }

      if (state.value != null) {
        return state.value!;
      }
      rethrow;
    }
  }

  Future<List<MemoModelPost>> _loadPosts(String profileId) async {
    try {
      final postRepository = ref.read(postRepositoryProvider);
      final postsStream = postRepository.getPostsByCreatorId(profileId);

      return await postsStream.first.timeout(Duration(seconds: 15));
    } catch (e) {
      print('Error loading posts: $e');
      return [];
    }
  }

  Future<void> refreshCreatorCache(String creatorId) async {
    final creatorRepository = ref.read(creatorRepositoryProvider);

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

  void forceRefreshAfterProfileSavedOnSettings() {
    _cache.remove(ref.read(userProvider)!.id);
    // _forceRefresh = true;
  }

  void refreshProfileDataAndStartBalanceTimer(int currentTabIndex, String profileId, bool isOwnProfile, BuildContext ctx) {
    ctx.afterBuild(refreshUI: false, () {
      if (currentTabIndex == 2) {
        if (_lastTabIndex != currentTabIndex || _lastProfileIdRefreshRequest != profileId) {
          // _forceRefresh = true;
          refreshUserRegisteredFlag();
          refreshCreatorCache(profileId);
          refreshBalances();
        }
        if (isOwnProfile) {
          startAutoRefreshBalanceProfile();
        }

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
      if (creator != null && !creator.hasRegisteredAsUserFixed) {
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

  Future<void> refreshMahakkaBalance(BuildContext ctx) async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null && creator.hasRegisteredAsUserFixed) {
        await creator.refreshBalanceMahakka(ref);
        _notifyStateUpdate(ctx);
      }
    }
  }

  Future<void> refreshMemoBalance(BuildContext ctx) async {
    final profileId = ref.read(_currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalanceMemo(ref);
        _notifyStateUpdate(ctx);
      }
    }
  }

  void _notifyStateUpdate(BuildContext ctx) {
    if (state.value != null && ctx.mounted) {
      state = AsyncValue.data(state.value!);
    }
  }

  void startQrDialogRefresh(bool isCashtokenMode, BuildContext ctx) {
    _isQrDialogOpen = true;
    _isQrCashtokenMode = isCashtokenMode;

    _stopQrDialogTimer();

    _qrDialogRefreshTimer = Timer.periodic(_qrRefreshInterval, (_) {
      if (_isQrDialogOpen && ctx.mounted) {
        _refreshQrDialogBalance(ctx);
      }
    });

    _refreshQrDialogBalance(ctx);
  }

  void stopQrDialogRefresh() {
    _isQrDialogOpen = false;
    _stopQrDialogTimer();
  }

  void setQrDialogMode(bool isCashtokenMode, BuildContext ctx) {
    _isQrCashtokenMode = isCashtokenMode;
    _refreshQrDialogBalance(ctx);
  }

  void _refreshQrDialogBalance(BuildContext ctx) {
    if (!_isQrDialogOpen || !ctx.mounted) return;

    if (_isQrCashtokenMode) {
      refreshMahakkaBalance(ctx);
    } else {
      refreshMemoBalance(ctx);
    }
  }

  void _stopQrDialogTimer() {
    _qrDialogRefreshTimer?.cancel();
    _qrDialogRefreshTimer = null;
  }

  void stopAutoRefreshBalanceProfile() {
    _stopProfileRefreshTimer();
  }

  void startAutoRefreshBalanceProfile() {
    _stopProfileRefreshTimer();
    _startBalanceRefreshTimerProfile();
  }

  void _startBalanceRefreshTimerProfile() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshBalancesPeriodicallyOnProfile();
    });
  }

  void _stopProfileRefreshTimer() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;
  }

  void _stopAllTimers() {
    _stopProfileRefreshTimer();
    _stopQrDialogTimer();
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

  void clearCache() {
    _cache.clear();
  }

  void clearCacheForProfile(String profileId) {
    _cache.remove(profileId);
  }
}

final postsStreamProvider = StreamProvider<List<MemoModelPost>>((ref) {
  final creatorId = ref.watch(_currentProfileIdProvider);
  if (creatorId == null || creatorId.isEmpty) {
    return const Stream.empty();
  }
  return ref.read(postRepositoryProvider).getPostsByCreatorId(creatorId);
});
