// providers/balance_watcher_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'electrum_provider.dart';

final balanceWatcherProvider = StreamProvider.autoDispose.family<Map<String, int>, String>((ref, String address) async* {
  final electrumService = await ref.watch(electrumServiceProvider.future);
  var previousBalance = <String, int>{'bch': -1, 'token': -1}; // Initialize with invalid values

  // Create a periodic stream that checks balances every 10 seconds
  final timer = Timer.periodic(const Duration(seconds: 10), (_) {});
  ref.onDispose(() => timer.cancel());

  while (true) {
    try {
      final balance = await electrumService.getBalances(address);

      // Check if balance has changed
      if (balance.bch != previousBalance['bch'] || balance.token != previousBalance['token']) {
        previousBalance = {'bch': balance.bch, 'token': balance.token};
        yield previousBalance; // Emit new balance
      }

      // Wait before next check
      await Future.delayed(const Duration(seconds: 10));
    } catch (e) {
      print('Error watching balance for address $address: $e');
      // Wait before retrying on error
      await Future.delayed(const Duration(seconds: 10));
    }
  }
});
