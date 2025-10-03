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
  final Duration _refreshBalanceInterval = Duration(seconds: kDebugMode ? 5 : 5);
  final Duration _qrRefreshInterval = Duration(seconds: kDebugMode ? 3 : 3);
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
      }
    }
  }

  Future<void> refreshMemoBalance(BuildContext ctx) async {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId != null && profileId.isNotEmpty) {
      final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
      if (creator != null) {
        await creator.refreshBalanceMemo(ref);
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
