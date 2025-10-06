import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/profile_data_model_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';

import '../providers/token_limits_provider.dart';

final profileBalanceProvider = Provider<ProfileBalanceProvider>((ref) {
  final provider = ProfileBalanceProvider(ref);
  ref.onDispose(() => provider.stopBalanceTimers());
  return provider;
});

class ProfileBalanceProvider {
  // Balance-related timers only
  Timer? _balanceRefreshTimer;
  Timer? _qrDialogRefreshTimer;
  final Duration _refreshBalanceInterval = Duration(seconds: kDebugMode ? 9 : 9);
  final Duration _qrRefreshInterval = Duration(seconds: kDebugMode ? 6 : 6);
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

  Future<void> refreshBalances(ctx) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      var creatorRepository = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepository.getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalances(ref, creatorRepository);
      }
    }

    ref.invalidate(creatorRepositoryProvider);
    ref.read(profileDataNotifier.notifier).notifyStateUpdateCreator(ctx);
    // ref.read(creatorRepositoryProvider).notifyCreatorUpdated(profileId, creator);
    // ref.read(tokenLimitsProvider.notifier).handleCreatorUpdate(creator);
  }

  Future<MemoModelCreator?> refreshMahakkaBalance(BuildContext ctx, String profileId) async {
    // if (profileId != null && profileId.isNotEmpty) {
    final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
    if (creator != null && creator.hasRegisteredAsUserFixed) {
      await creator.refreshBalanceMahakka(ref);
      return creator;
    }
    return null;
    // }
  }

  Future<MemoModelCreator?> refreshMemoBalance(BuildContext ctx, String profileId) async {
    // if (profileId != null && profileId.isNotEmpty) {
    final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
    if (creator != null) {
      await creator.refreshBalanceMemo(ref);
      return creator;
    }
    return null;
    // }
  }

  void startQrDialogRefresh(bool isCashtokenMode, BuildContext ctx, String profileId) {
    _isQrDialogOpen = true;
    _isQrCashtokenMode = isCashtokenMode;

    _stopQrDialogTimer();

    _qrDialogRefreshTimer = Timer.periodic(_qrRefreshInterval, (_) {
      if (_isQrDialogOpen && ctx.mounted) {
        _refreshQrDialogBalance(ctx, profileId);
      }
    });

    _refreshQrDialogBalance(ctx, profileId);
  }

  void stopQrDialogRefresh() {
    _isQrDialogOpen = false;
    _stopQrDialogTimer();
  }

  void setQrDialogMode(bool isCashtokenMode, BuildContext ctx, String profileId) {
    _isQrCashtokenMode = isCashtokenMode;
    _refreshQrDialogBalance(ctx, profileId);
  }

  void _refreshQrDialogBalance(BuildContext ctx, String profileId) async {
    if (!_isQrDialogOpen || !ctx.mounted) return;

    MemoModelCreator? creator;
    if (_isQrCashtokenMode) {
      creator = await refreshMahakkaBalance(ctx, profileId);
    } else {
      creator = await refreshMemoBalance(ctx, profileId);
    }
    ref.invalidate(creatorRepositoryProvider);
    ref.read(profileDataNotifier.notifier).notifyStateUpdateCreator(ctx);
    ref.read(creatorRepositoryProvider).notifyCreatorUpdated(profileId, creator);
    ref.read(tokenLimitsProvider.notifier).handleCreatorUpdate(creator);
  }

  void _stopQrDialogTimer() {
    _qrDialogRefreshTimer?.cancel();
    _qrDialogRefreshTimer = null;
  }

  void stopAutoRefreshBalanceProfile() {
    _stopProfileRefreshTimer();
  }

  void startAutoRefreshBalanceProfile(ctx) {
    _stopProfileRefreshTimer();
    _startBalanceRefreshTimerProfile(ctx);
  }

  void _startBalanceRefreshTimerProfile(ctx) {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      await _refreshBalancesPeriodicallyOnProfile(ctx);
    });
  }

  void _stopProfileRefreshTimer() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;
  }

  Future<void> _refreshBalancesPeriodicallyOnProfile(ctx) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null || profileId.isEmpty || ref.read(profileDataNotifier).isLoading) {
      return;
    }

    try {
      final currentData = ref.read(profileDataNotifier.notifier).state.value;
      if (currentData != null && currentData.creator != null) {
        Future.microtask(() async {
          await refreshBalances(ctx);
        });
      }
    } catch (e) {
      if (kDebugMode) print('Periodic balance refresh failed: $e');
    }
  }
}
