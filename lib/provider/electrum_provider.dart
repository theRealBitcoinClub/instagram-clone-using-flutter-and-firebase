// providers/electrum_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memo/base/memo_bitcoin_base.dart';

final electrumServiceProvider = AsyncNotifierProvider<ElectrumServiceNotifier, MemoBitcoinBase>(() {
  return ElectrumServiceNotifier();
});

class ElectrumServiceNotifier extends AsyncNotifier<MemoBitcoinBase> {
  @override
  Future<MemoBitcoinBase> build() async {
    final service = await MemoBitcoinBase.create();

    // Register the onDispose hook.
    // This callback will be executed when the provider is disposed.
    ref.onDispose(() {
      // Close the WebSocket connection.
      service.service?.discounnect();
    });

    return service;
  }
}
