// lib/providers/profile_providers.dart

import 'dart:async';

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
final profileCreatorStateProvider = AsyncNotifierProvider<CreatorNotifier, MemoModelCreator?>(() => CreatorNotifier());

class CreatorNotifier extends AsyncNotifier<MemoModelCreator?> {
  Timer? _balanceRefreshTimer;
  Timer? _mahakkaBalanceRefreshTimer;
  Timer? _memoBalanceRefreshTimer;
  Duration _refreshBalanceInterval = Duration(seconds: 3);

  DateTime? _lastRefreshTime;
  bool _isAutoRefreshRunning = false;

  @override
  Future<MemoModelCreator?> build() async {
    final creatorId = ref.watch(_currentProfileIdProvider);

    // Debounce rapid rebuilds
    final now = DateTime.now();
    if (_lastRefreshTime != null && now.difference(_lastRefreshTime!) < Duration(seconds: 1)) {
      return state.value; // Return current state if recently refreshed
    }

    _lastRefreshTime = now;

    if (creatorId == null || creatorId.isEmpty) {
      // Return null or throw a specific error if no ID is available
      return null;
    }
    //TODO WHERE AND WHEN MUST I REFRESH WHAT
    CreatorRepository creatorRepository = ref.read(creatorRepositoryProvider);
    // await creatorRepository.refreshCreatorCache(creatorId, () {}, () {});
    MemoModelCreator? creator = await creatorRepository.getCreator(creatorId);
    // if (creator!.hasRegisteredAsUser) await creator.refreshBalanceMahakka();
    // await creator.refreshBalanceMemo();
    return creator;
  }

  //TODO MAKE SURE THIS IS ONLY TRIGGERED ON SUCCESS OF PROFILE SAVE
  Future<void> refreshCreatorCache(String creatorId) async {
    CreatorRepository creatorRepository = ref.read(creatorRepositoryProvider);
    creatorRepository.refreshCreatorCache(
      creatorId,
      () {
        print("refreshCreatorCache fresh scrape success for creatorId ${creatorId}");
      },
      () {
        print("refreshCreatorCache no fresh data avaiable for creatorId ${creatorId}");
      },
      () {
        print("refreshCreatorCache scrape failed for creatorId ${creatorId}");
      },
    );
  }

  //TODO this is triggered by the set methods
  //TODO check if the set methods should be better placed in profile provider
  // Future<void> refreshProfileImages(String forceImageType) async {
  //   final creatorId = ref.read(_currentProfileIdProvider);
  //   if (creatorId != null && creatorId.isNotEmpty) {
  //     state = const AsyncValue.loading();
  //     state = await AsyncValue.guard(() async {
  //       var creator = await ref.read(creatorRepositoryProvider).getCreator(creatorId);
  //       await creator!.refreshAvatar(forceImageType: forceImageType, forceRefreshAfterProfileUpdate: true);
  //       //TODO also update the detail
  //       // await creator!.refreshAvatarDetail(forceImageType: forceImageType, forceRefreshAfterProfileUpdate: true);
  //       return creator;
  //     });
  //   }
  // }

  // TODO MAKE SURE THIS IS ONLY TRIGGERED ON SUCCESS OF PROFILE SAVE
  // TODO manually triggered by user refresh pull down in addition to current auto build method call? or just rebuild all on refresh?
  Future<void> refreshUserRegisteredFlag() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId != null && creatorId.isNotEmpty) {
      //TODO  asyncvalue loading seems to triger the watch events cant be used inside build methods
      // state = const AsyncValue.loading();
      // state = await AsyncValue.guard(() async {
      var creator = await ref.read(creatorRepositoryProvider).getCreator(creatorId);
      await creator!.refreshUserHasRegistered(ref);
      // return creator;
      // });
    }
  }

  // timer triggered
  Future<void> refreshBalances() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId != null && creatorId.isNotEmpty) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        var creator = await ref.read(creatorRepositoryProvider).getCreator(creatorId);
        await creator!.refreshBalances(ref);
        return creator;
      });
    }
  }

  // Refresh only Mahakka balance
  Future<void> refreshMahakkaBalance() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId != null && creatorId.isNotEmpty && state.value != null) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        var creator = await ref.read(creatorRepositoryProvider).getCreator(creatorId);
        await creator!.refreshBalanceMahakka(ref);
        return creator;
      });
    }
  }

  // Refresh only Memo balance
  Future<void> refreshMemoBalance() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId != null && creatorId.isNotEmpty && state.value != null) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        var creator = await ref.read(creatorRepositoryProvider).getCreator(creatorId);
        await creator!.refreshBalanceMemo(ref);
        return creator;
      });
    }
  }

  // Check if auto-refresh is currently running
  bool isAutoRefreshRunning() {
    return _isAutoRefreshRunning;
  }

  // Optional: Method to manually change refresh interval
  void setRefreshInterval(Duration interval) {
    _refreshBalanceInterval = interval;
    // Restart any active timers with new interval
    if (_balanceRefreshTimer != null) {
      startAutoRefreshBalance();
    } else if (_mahakkaBalanceRefreshTimer != null) {
      startAutoRefreshMahakkaBalance();
    } else if (_memoBalanceRefreshTimer != null) {
      startAutoRefreshMemoBalance();
    }
  }

  // Optional: Method to stop automatic refreshing
  void stopAutoRefreshBalance() {
    _stopAllBalanceTimers();
    _isAutoRefreshRunning = false;
  }

  // Optional: Method to start automatic refreshing (both balances)
  void startAutoRefreshBalance() {
    _stopAllBalanceTimers();
    _isAutoRefreshRunning = true;
    _startBalanceRefreshTimer();
  }

  // Auto-refresh for Mahakka balance only - for QR Code dialog
  void startAutoRefreshMahakkaBalance() {
    // Only start if auto-refresh isn't already running (i.e., not on profile tab)
    if (!_isAutoRefreshRunning) {
      _stopAllBalanceTimers();
      _startMahakkaBalanceRefreshTimer();
    }
  }

  // Auto-refresh for Memo balance only - for QR Code dialog
  void startAutoRefreshMemoBalance() {
    // Only start if auto-refresh isn't already running (i.e., not on profile tab)
    if (!_isAutoRefreshRunning) {
      _stopAllBalanceTimers();
      _startMemoBalanceRefreshTimer();
    }
  }

  void _startBalanceRefreshTimer() {
    // Cancel any existing timer
    _balanceRefreshTimer?.cancel();

    // Start a new periodic timer
    _balanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshBalancesPeriodically();
    });
  }

  void _startMahakkaBalanceRefreshTimer() {
    _mahakkaBalanceRefreshTimer?.cancel();
    _mahakkaBalanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshMahakkaBalancePeriodically();
    });
  }

  void _startMemoBalanceRefreshTimer() {
    _memoBalanceRefreshTimer?.cancel();
    _memoBalanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshMemoBalancePeriodically();
    });
  }

  void _stopAllBalanceTimers() {
    //TODO MAKE SURE BALANCE REFRESH IS STILL RUNNING WHILE ON PROFILE
    // _balanceRefreshTimer?.cancel();
    _mahakkaBalanceRefreshTimer?.cancel();
    _memoBalanceRefreshTimer?.cancel();
    // _balanceRefreshTimer = null;
    _mahakkaBalanceRefreshTimer = null;
    _memoBalanceRefreshTimer = null;
  }

  Future<void> _refreshBalancesPeriodically() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId == null || creatorId.isEmpty || state.isLoading) {
      return; // Skip if no creator ID or already loading
    }

    try {
      // Get the current creator to check if we need to refresh
      final currentCreator = state.value;
      if (currentCreator != null) {
        // Only refresh if the creator is a registered user
        // if (currentCreator.hasRegisteredAsUser) {
        await refreshBalances();
        // }
      }
    } catch (e) {
      print('Periodic balance refresh failed: $e');
      // Don't update state on periodic refresh failures to avoid UI disruption
    }
  }

  Future<void> _refreshMahakkaBalancePeriodically() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId == null || creatorId.isEmpty || state.isLoading) {
      return;
    }

    try {
      final currentCreator = state.value;
      if (currentCreator != null && currentCreator.hasRegisteredAsUser) {
        await refreshMahakkaBalance();
      }
    } catch (e) {
      print('Periodic Mahakka balance refresh failed: $e');
    }
  }

  Future<void> _refreshMemoBalancePeriodically() async {
    final creatorId = ref.read(_currentProfileIdProvider);
    if (creatorId == null || creatorId.isEmpty || state.isLoading) {
      return;
    }

    try {
      final currentCreator = state.value;
      if (currentCreator != null) {
        await refreshMemoBalance();
      }
    } catch (e) {
      print('Periodic Memo balance refresh failed: $e');
    }
  }

  void dispose() {
    _stopAllBalanceTimers();
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
