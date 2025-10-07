// bch_burner_balance_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';

import 'electrum_provider.dart';

final bchBurnerBalanceProvider = StreamProvider<Balance>((ref) {
  final streamController = StreamController<Balance>();
  Timer? timer;

  // Initial load
  _fetchBalance(ref).then((balance) {
    streamController.add(balance);
  });

  timer = Timer.periodic(const Duration(seconds: kDebugMode ? 300 : 10), (_) async {
    try {
      final balance = await _fetchBalance(ref);
      print('Update burner balance: $balance');
      streamController.add(balance);
    } catch (error) {
      // Handle error, optionally add error state to stream
      print('Error fetching burner balance: $error');
    }
  });

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
