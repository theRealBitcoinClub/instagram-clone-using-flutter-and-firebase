import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/profile_data_model_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';

final profileBalanceProvider = Provider<ProfileBalanceProvider>((ref) {
  final provider = ProfileBalanceProvider(ref);
  ref.onDispose(() => provider.stopBalanceTimers());
  return provider;
});

class ProfileBalanceProvider {
  // Balance-related timers only
  Timer? _balanceRefreshTimer;
  Timer? _qrDialogRefreshTimer;
  final Duration _refreshBalanceInterval = Duration(seconds: kDebugMode ? 50 : 5);
  final Duration _qrRefreshInterval = Duration(seconds: kDebugMode ? 30 : 3);
  bool _isQrDialogOpen = false;
  bool _isQrCashtokenMode = false;
  Ref ref;

  ProfileBalanceProvider(this.ref);

  // Balance-related methods only
  void stopBalanceTimers() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;
    _qrDialogRefreshTimer?.cancel();
    _qrDialogRefreshTimer = null;
  }

  Future<void> refreshBalances() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      var creatorRepository = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepository.getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalances(ref, creatorRepository);
      }
    }
  }

  Future<void> refreshMahakkaBalance(BuildContext ctx) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null && creator.hasRegisteredAsUserFixed) {
        await creator.refreshBalanceMahakka(ref);
        ref.read(profileDataNotifier.notifier).notifyStateUpdate(ctx);
      }
    }
  }

  Future<void> refreshMemoBalance(BuildContext ctx) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalanceMemo(ref);
        ref.read(profileDataNotifier.notifier).notifyStateUpdate(ctx);
      }
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

  Future<void> _refreshBalancesPeriodicallyOnProfile() async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null || profileId.isEmpty || ref.read(profileDataNotifier).isLoading) {
      return;
    }

    try {
      final currentData = ref.read(profileDataNotifier.notifier).state.value;
      if (currentData != null && currentData.creator != null) {
        Future.microtask(() async {
          await refreshBalances();
        });
      }
    } catch (e) {
      if (kDebugMode) print('Periodic balance refresh failed: $e');
    }
  }
}

// I have a widget thats called profile_screen_widget that shall load creatorId specific profile data when the user navigates back and forth from feed to profile, that data shall be refreshed once per profile load and the user can not trigger any manual refresh except by navigating back and forth, now there is profile data that is settings specific that is stored inside the creator object, that creator data within the ProfileData must be subscribed to and it must be updated every time the balance refresh timers or the settings_widget save method triggers an update to that data, while the ProfileData posts data will only ever be refreshed when the user navigates therefore the currentProfileId doesnt match the lastProfileId anymore, the profileId is equal to creatorId, now I have a firebase storage which is the single source of truth from where I load an amount of posts filtered by creatorId limited by profileCacheAndFirebaseLimit, I want that method which is currently using a stream implementation to use a more simple list implementation as the data is already limited in length/count, now after the load from firebase that data must be stored in the local isar database from where it is finally fetched to be displayed in profile_screen_widget, meaning the UI layer interacts with the isar layer and isar layer interacts with firebase layer, when finally fetching the data from isar it shall apply the same limit to display only a specific amount of posts, now the isar storage is limited on size, it has a fixed size limit and a tolerance thats being checked on to cleanup the database after storage requests whenever necessary, now let me explain the user flow to be clear what happens when the user loads a profile initially, the first time the user loads a profile there is a counter check that will result in a null value meaning its default value 0, that counter shall be stored in sharedpreferences using the sharedPreferencesProvider, that first time profile request shall trigger a firebase fetch limited on the profileCacheAndFirebaseLimit where the results are stored in isar to then be displayed via profile_screen_widget, now the tricky part is when the user reloads a profile he had already visited, then the stored counter which results from a firebase count request with a filter on creatorId must be compared to the current counter value and only if there is a difference a firebase fetch shall be triggered, that firebase fetch shall then fetch the difference of items in post count while still respecting the total limit profileCacheAndFirebaseLimit so in case a user has a fresh count thats 44 and the old count was 14 that would be 30 new items, but that request will be limited to profileCacheAndFirebaseLimit in any way, now that new data is stored in isar and the query thats been ex ecuted on isar to display the data in the frontend will only display these new items as they already fill the limits as they are also applied to isar requests, now the data inside isar will become stale and be sitting there until the cleanup process pushes that data out, let me provide you with the current classes and implementation so you can come up with the full code examples for all the classes involved, please add excessive print statements that are easily identifiable for the logfilter, they shall always have a prefix similar to the existing pattern thats derived from the class name so its unique to the class that means we can verify later on that everything is executed as expected as i can provide you with these logs, whenever you add the print log statements make sure to add if (_debugMode) where _debugMode is a class specific boolean thats default value is kDebugMode, make sure that any existing logic thats not within the new requirements remains as it is, the code curently compiles so you can assume that all the methods to which i do not provide code do actually exist and work as expected but if you need more input please let me know, i want a bulletproof solution:
