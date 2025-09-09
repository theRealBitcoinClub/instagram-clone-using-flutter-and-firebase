import 'dart:async';

import 'package:mahakka/memo/base/memo_bitcoin_base.dart';

class DebouncedBalanceService {
  final MemoBitcoinBase _balanceService;
  final Debouncer<String, Balance> _debouncer;

  DebouncedBalanceService(this._balanceService, {Duration debounceDuration = const Duration(seconds: 15)})
    : _debouncer = Debouncer<String, Balance>(debounceDuration: debounceDuration, fetcher: (address) => _balanceService.getBalances(address));

  Future<Balance> getBalances(String address) {
    return _debouncer.fetch(address);
  }

  // void clearCacheForAddress(String address) {
  //   _debouncer.clearCache(address);
  // }
  //
  // void clearCache() {
  //   _debouncer.clearCache();
  // }
}

// Generic debouncer class that can be reused
class Debouncer<K, V> {
  final Duration debounceDuration;
  final Future<V> Function(K key) fetcher;

  final Map<K, _CachedValue<V>> _cache = {};
  final Map<K, Future<V>> _ongoingRequests = {};

  Debouncer({required this.debounceDuration, required this.fetcher});

  Future<V> fetch(K key) async {
    final now = DateTime.now();

    // Return cached result if valid
    final cached = _cache[key];
    if (cached != null && now.difference(cached.timestamp) < debounceDuration) {
      return cached.value;
    }

    // Return ongoing request if exists
    if (_ongoingRequests.containsKey(key)) {
      return _ongoingRequests[key]!;
    }

    try {
      final future = fetcher(key);
      _ongoingRequests[key] = future;

      final result = await future;

      // Cache the result
      _cache[key] = _CachedValue(now, result);

      return result;
    } finally {
      _ongoingRequests.remove(key);
      _cleanupCache();
    }
  }

  // void clearCache([K? key]) {
  //   if (key != null) {
  //     _cache.remove(key);
  //     _ongoingRequests.remove(key);
  //   } else {
  //     _cache.clear();
  //     _ongoingRequests.clear();
  //   }
  // }

  void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = _cache.keys.where((k) {
      return now.difference(_cache[k]!.timestamp) > debounceDuration;
    }).toList();

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}

class _CachedValue<V> {
  final DateTime timestamp;
  final V value;

  _CachedValue(this.timestamp, this.value);
}
