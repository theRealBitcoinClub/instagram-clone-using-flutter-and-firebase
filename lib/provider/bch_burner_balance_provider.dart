// bch_burner_balance_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';

import 'electrum_provider.dart';

final bchBurnerBalanceProvider = StreamProvider.autoDispose<Balance>((ref) {
  final streamController = StreamController<Balance>();
  Timer? timer;

  // Initial load
  _fetchBalance(ref).then((balance) {
    streamController.add(balance);
  });

  // Set up periodic updates every 5 seconds
  timer = Timer.periodic(const Duration(seconds: 5), (_) async {
    try {
      final balance = await _fetchBalance(ref);
      streamController.add(balance);
    } catch (error) {
      // Handle error, optionally add error state to stream
      print('Error fetching burner balance: $error');
    }
  });

  // Clean up when the provider is disposed
  ref.onDispose(() {
    timer?.cancel();
    streamController.close();
  });

  return streamController.stream;
});

Future<Balance> _fetchBalance(Ref ref) async {
  final MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
  return await base.getBalances(MemoBitcoinBase.bchBurnerAddress);
}
