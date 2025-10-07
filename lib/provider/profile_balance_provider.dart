import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/profile_data_model_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';

import '../providers/token_limits_provider.dart';

final profileBalanceProvider = Provider<ProfileBalanceProvider>((ref) {
  print('🔄 PBP: 🔧 Creating ProfileBalanceProvider instance');
  final provider = ProfileBalanceProvider(ref);
  ref.onDispose(() {
    print('🗑️ PBP: ♻️ ProfileBalanceProvider disposed - stopping timers');
    provider.stopBalanceTimers();
  });
  return provider;
});

class ProfileBalanceProvider {
  // Balance-related timers only
  Timer? _balanceRefreshTimer;
  Timer? _qrDialogRefreshTimer;
  final Duration _refreshBalanceInterval = Duration(seconds: kDebugMode ? 90 : 9);
  final Duration _qrRefreshInterval = Duration(seconds: kDebugMode ? 60 : 6);
  bool _isQrDialogOpen = false;
  bool _isQrCashtokenMode = false;
  final Ref ref;

  // Debug mode
  final bool _debugMode = kDebugMode;

  ProfileBalanceProvider(this.ref) {
    _print('🔄 PBP: 🏗️ ProfileBalanceProvider constructor called');
  }

  // Encapsulated print method
  void _print(String message) {
    if (_debugMode) {
      print(message);
    }
  }

  // Balance-related methods only
  void stopBalanceTimers() {
    _print('⏹️ PBP: ⏰ Stopping all balance timers');
    _print(
      '📊 PBP: 📈 Timer states before stop - Balance: ${_balanceRefreshTimer != null ? "RUNNING" : "STOPPED"}, QR: ${_qrDialogRefreshTimer != null ? "RUNNING" : "STOPPED"}',
    );

    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;
    _qrDialogRefreshTimer?.cancel();
    _qrDialogRefreshTimer = null;

    _print('✅ PBP: ⏰ All timers stopped successfully');
  }

  Future<void> refreshBalances(BuildContext ctx) async {
    _print('🔄 PBP: 💰 refreshBalances() called');
    _print('🌳 PBP: 📍 Execution path: refreshBalances() → getCreator() → refreshBalances() → notifyStateUpdateCreator()');

    final profileId = ref.read(currentProfileIdProvider);
    _print('👤 PBP: 🔍 Current profile ID: ${profileId ?? "NULL"}');

    if (profileId != null && profileId.isNotEmpty) {
      _print('✅ PBP: 👤 Valid profile ID found, proceeding with balance refresh');
      var creatorRepository = ref.read(creatorRepositoryProvider);
      _print('🔧 PBP: 🛠️ Creator repository obtained');

      final creator = await creatorRepository.getCreator(profileId, saveToFirebase: false);
      _print('👤 PBP: 🔍 Creator fetched: ${creator != null ? "SUCCESS" : "FAILED"}');

      if (creator != null) {
        _print('🔄 PBP: 💾 Starting balance refresh for creator: ${creator.id}');
        await creator.refreshBalances(ref, creatorRepository);
        _print('✅ PBP: 💰 Balance refresh completed for creator: ${creator.id}');
      } else {
        _print('❌ PBP: 👤 Creator is null, skipping balance refresh');
      }

      _print('📢 PBP: 🔄 Notifying state update for creator');
      ref.read(profileDataNotifier.notifier).notifyStateUpdateCreator(ctx, c: creator);
      _print('📢 PBP: 🔄 Notifying creator repository of update');
      ref.read(creatorRepositoryProvider).notifyCreatorUpdated(profileId, creator);
      _print('✅ PBP: 📢 All notifications sent');
    } else {
      _print('❌ PBP: 👤 No valid profile ID, skipping balance refresh');
    }

    _print('✅ PBP: 💰 refreshBalances() completed');
  }

  Future<MemoModelCreator?> refreshMahakkaBalance(BuildContext ctx, String profileId) async {
    _print('🔄 PBP: 🪙 refreshMahakkaBalance() called for profile: $profileId');
    _print('🌳 PBP: 📍 Execution path: refreshMahakkaBalance() → getCreator() → refreshBalanceMahakka()');

    final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
    _print('👤 PBP: 🔍 Creator fetched for Mahakka balance: ${creator != null ? "SUCCESS" : "FAILED"}');

    if (creator != null && creator.hasRegisteredAsUserFixed) {
      _print('✅ PBP: 👤 Creator is registered user, refreshing Mahakka balance');
      await creator.refreshBalanceMahakka(ref);
      _print('✅ PBP: 🪙 Mahakka balance refresh completed');
      return creator;
    } else {
      if (creator == null) {
        _print('❌ PBP: 👤 Creator is null, cannot refresh Mahakka balance');
      } else {
        _print(
          '❌ PBP: 👤 Creator not registered as user (hasRegisteredAsUserFixed: ${creator.hasRegisteredAsUserFixed}), skipping Mahakka balance refresh',
        );
      }
      return null;
    }
  }

  Future<MemoModelCreator?> refreshMemoBalance(BuildContext ctx, String profileId) async {
    _print('🔄 PBP: 📝 refreshMemoBalance() called for profile: $profileId');
    _print('🌳 PBP: 📍 Execution path: refreshMemoBalance() → getCreator() → refreshBalanceMemo()');

    final creator = await ref.read(creatorRepositoryProvider).getCreator(profileId, saveToFirebase: false);
    _print('👤 PBP: 🔍 Creator fetched for Memo balance: ${creator != null ? "SUCCESS" : "FAILED"}');

    if (creator != null) {
      _print('✅ PBP: 👤 Creator found, refreshing Memo balance');
      await creator.refreshBalanceMemo(ref);
      _print('✅ PBP: 📝 Memo balance refresh completed');
      return creator;
    } else {
      _print('❌ PBP: 👤 Creator is null, cannot refresh Memo balance');
      return null;
    }
  }

  void startQrDialogRefresh(bool isCashtokenMode, BuildContext ctx, String profileId) {
    _print('🔄 PBP: 📱 startQrDialogRefresh() called');
    _print('⚙️ PBP: 🔧 Parameters - isCashtokenMode: $isCashtokenMode, profileId: $profileId');
    _print('🌳 PBP: 📍 Execution path: startQrDialogRefresh() → _stopQrDialogTimer() → Timer.periodic() → _refreshQrDialogBalance()');

    _isQrDialogOpen = true;
    _isQrCashtokenMode = isCashtokenMode;
    _print('📱 PBP: 🎯 QR Dialog state - Open: $_isQrDialogOpen, CashtokenMode: $_isQrCashtokenMode');

    _stopQrDialogTimer();
    _print('⏹️ PBP: ⏰ Previous QR timer stopped');

    _qrDialogRefreshTimer = Timer.periodic(_qrRefreshInterval, (_) {
      _print('🔄 PBP: 🔄 QR Dialog timer tick - Open: $_isQrDialogOpen, Context mounted: ${ctx.mounted}');
      if (_isQrDialogOpen && ctx.mounted) {
        _print('✅ PBP: 🎯 Conditions met, refreshing QR dialog balance');
        _refreshQrDialogBalance(ctx, profileId);
      } else {
        _print('❌ PBP: 🚫 Conditions not met - QR dialog closed or context unmounted');
      }
    });

    _print('✅ PBP: ⏰ QR Dialog refresh timer started with interval: ${_qrRefreshInterval.inSeconds}s');
    _refreshQrDialogBalance(ctx, profileId);
    _print('✅ PBP: 📱 startQrDialogRefresh() completed');
  }

  void stopQrDialogRefresh() {
    _print('🔄 PBP: 📱 stopQrDialogRefresh() called');
    _print('🌳 PBP: 📍 Execution path: stopQrDialogRefresh() → _stopQrDialogTimer()');

    _isQrDialogOpen = false;
    _print('📱 PBP: 🎯 QR Dialog state set to closed');

    _stopQrDialogTimer();
    _print('✅ PBP: 📱 stopQrDialogRefresh() completed');
  }

  void setQrDialogMode(bool isCashtokenMode, BuildContext ctx, String profileId) {
    _print('🔄 PBP: ⚙️ setQrDialogMode() called');
    _print('⚙️ PBP: 🔧 New mode - isCashtokenMode: $isCashtokenMode, profileId: $profileId');
    _print('🌳 PBP: 📍 Execution path: setQrDialogMode() → _refreshQrDialogBalance()');

    _isQrCashtokenMode = isCashtokenMode;
    _print('📱 PBP: 🎯 QR Dialog mode updated to CashtokenMode: $_isQrCashtokenMode');

    _refreshQrDialogBalance(ctx, profileId);
    _print('✅ PBP: ⚙️ setQrDialogMode() completed');
  }

  void _refreshQrDialogBalance(BuildContext ctx, String profileId) async {
    _print('🔄 PBP: 📱 _refreshQrDialogBalance() called');
    _print('📱 PBP: 🎯 Current state - QR Dialog Open: $_isQrDialogOpen, Context mounted: ${ctx.mounted}');

    if (!_isQrDialogOpen || !ctx.mounted) {
      _print('❌ PBP: 🚫 Conditions not met for QR dialog refresh');
      return;
    }

    _print('✅ PBP: 🎯 Conditions met, proceeding with QR balance refresh');
    MemoModelCreator? creator;

    if (_isQrCashtokenMode) {
      _print('🔄 PBP: 🪙 Refreshing Mahakka balance for QR dialog');
      creator = await refreshMahakkaBalance(ctx, profileId);
    } else {
      _print('🔄 PBP: 📝 Refreshing Memo balance for QR dialog');
      creator = await refreshMemoBalance(ctx, profileId);
    }

    _print('👤 PBP: 🔍 QR Dialog balance refresh result - Creator: ${creator != null ? "SUCCESS" : "NULL"}');

    _print('📢 PBP: 🔄 Invalidating creator repository');
    ref.invalidate(creatorRepositoryProvider);

    _print('📢 PBP: 🔄 Notifying profile data state update');
    ref.read(profileDataNotifier.notifier).notifyStateUpdateCreator(ctx);

    _print('📢 PBP: 🔄 Notifying creator repository of update');
    ref.read(creatorRepositoryProvider).notifyCreatorUpdated(profileId, creator);

    _print('📢 PBP: 🔄 Handling token limits update');
    ref.read(tokenLimitsProvider.notifier).handleCreatorUpdateOnlyIfOwnCreator(creator);

    _print('✅ PBP: 📱 _refreshQrDialogBalance() completed');
  }

  void _stopQrDialogTimer() {
    _print('🔄 PBP: ⏰ _stopQrDialogTimer() called');
    _print('📊 PBP: 📈 QR Timer state before stop: ${_qrDialogRefreshTimer != null ? "RUNNING" : "STOPPED"}');

    _qrDialogRefreshTimer?.cancel();
    _qrDialogRefreshTimer = null;

    _print('✅ PBP: ⏰ QR Dialog timer stopped');
  }

  void stopAutoRefreshBalanceProfile() {
    _print('🔄 PBP: ⏹️ stopAutoRefreshBalanceProfile() called');
    _print('🌳 PBP: 📍 Execution path: stopAutoRefreshBalanceProfile() → _stopProfileRefreshTimer()');

    _stopProfileRefreshTimer();
    _print('✅ PBP: ⏹️ stopAutoRefreshBalanceProfile() completed');
  }

  void startAutoRefreshBalanceProfile(BuildContext ctx) {
    _print('🔄 PBP: ▶️ startAutoRefreshBalanceProfile() called');
    _print('🌳 PBP: 📍 Execution path: startAutoRefreshBalanceProfile() → _stopProfileRefreshTimer() → _startBalanceRefreshTimerProfile()');

    _stopProfileRefreshTimer();
    _startBalanceRefreshTimerProfile(ctx);
    _print('✅ PBP: ▶️ startAutoRefreshBalanceProfile() completed');
  }

  void _startBalanceRefreshTimerProfile(BuildContext ctx) {
    _print('🔄 PBP: ⏰ _startBalanceRefreshTimerProfile() called');
    _print('📊 PBP: 📈 Balance Timer state before start: ${_balanceRefreshTimer != null ? "RUNNING" : "STOPPED"}');

    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = Timer.periodic(_refreshBalanceInterval, (_) async {
      _print('🔄 PBP: 🔄 Profile balance timer tick');
      await _refreshBalancesPeriodicallyOnProfile(ctx);
    });

    _print('✅ PBP: ⏰ Profile balance refresh timer started with interval: ${_refreshBalanceInterval.inSeconds}s');
  }

  void _stopProfileRefreshTimer() {
    _print('🔄 PBP: ⏰ _stopProfileRefreshTimer() called');
    _print('📊 PBP: 📈 Profile Timer state before stop: ${_balanceRefreshTimer != null ? "RUNNING" : "STOPPED"}');

    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;

    _print('✅ PBP: ⏰ Profile refresh timer stopped');
  }

  Future<void> _refreshBalancesPeriodicallyOnProfile(BuildContext ctx) async {
    _print('🔄 PBP: 🔄 _refreshBalancesPeriodicallyOnProfile() called');
    _print('🌳 PBP: 📍 Execution path: _refreshBalancesPeriodicallyOnProfile() → refreshBalances()');

    final profileId = ref.read(currentProfileIdProvider);
    _print('👤 PBP: 🔍 Current profile ID for periodic refresh: ${profileId ?? "NULL"}');

    if (profileId == null || profileId.isEmpty) {
      _print('❌ PBP: 👤 No profile ID available for periodic refresh');
      return;
    }

    final isLoading = ref.read(profileDataNotifier).isLoading;
    _print('📊 PBP: 📈 Profile data loading state: $isLoading');

    if (ref.read(profileDataNotifier).isLoading) {
      _print('❌ PBP: ⏳ Profile data is currently loading, skipping periodic refresh');
      return;
    }

    try {
      _print('🔍 PBP: 🔄 Checking current profile data state');
      final currentData = ref.read(profileDataNotifier.notifier).state.value;
      final hasCreator = currentData != null && currentData.creator != null;
      _print('👤 PBP: 🔍 Current data state - Has data: ${currentData != null}, Has creator: ${hasCreator}');

      if (hasCreator) {
        _print('✅ PBP: 👤 Valid creator found, scheduling balance refresh');
        Future.microtask(() async {
          _print('🔄 PBP: 🔄 Microtask executing balance refresh');
          await refreshBalances(ctx);
          _print('✅ PBP: 🔄 Microtask balance refresh completed');
        });
      } else {
        _print('❌ PBP: 👤 No creator available for periodic refresh');
      }
    } catch (e) {
      _print('❌ PBP: 🚨 Periodic balance refresh failed: $e');
    }

    _print('✅ PBP: 🔄 _refreshBalancesPeriodicallyOnProfile() completed');
  }
}
