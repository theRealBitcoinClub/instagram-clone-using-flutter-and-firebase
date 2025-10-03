// import 'dart:async';
//
// import 'memo_bitcoin_base.dart';
//
// class DebouncedBalanceService {
//   final Debouncer<String, Balance> _debouncer;
//
//   DebouncedBalanceService({required MemoBitcoinBase balanceService, Duration debounceDelay = const Duration(seconds: 15)})
//     : _debouncer = Debouncer<String, Balance>(debounceDuration: debounceDelay, fetcher: balanceService.getBalances);
//
//   Future<Balance> getBalances(String address) => _debouncer.fetch(address);
// }
//
// class Debouncer<K, V> {
//   final Duration debounceDuration;
//   final Future<V> Function(K key) fetcher;
//
//   final Map<K, _CachedValue<V>> _cache = {};
//   final Map<K, Future<V>> _ongoingRequests = {};
//   Timer? _cleanupTimer;
//
//   Debouncer({required this.debounceDuration, required this.fetcher}) {
//     // Setup periodic cleanup
//     _cleanupTimer = Timer.periodic(Duration(minutes: 1), (_) => _cleanupCache());
//   }
//
//   Future<V> fetch(K key) async {
//     final now = DateTime.now();
//
//     // Return cached result if valid
//     final cached = _cache[key];
//     if (cached != null && now.difference(cached.timestamp) < debounceDuration) {
//       return cached.value;
//     }
//
//     // Return ongoing request if exists
//     if (_ongoingRequests.containsKey(key)) {
//       return _ongoingRequests[key]!;
//     }
//
//     try {
//       final future = fetcher(key);
//       _ongoingRequests[key] = future;
//
//       final result = await future;
//
//       // Cache the result
//       _cache[key] = _CachedValue(DateTime.now(), result);
//
//       return result;
//     } catch (e) {
//       // Important: Remove from ongoing requests on error
//       _ongoingRequests.remove(key);
//       rethrow;
//     } finally {
//       _ongoingRequests.remove(key);
//     }
//   }
//
//   void _cleanupCache() {
//     final now = DateTime.now();
//     final expiredKeys = _cache.keys.where((k) {
//       return now.difference(_cache[k]!.timestamp) > debounceDuration;
//     }).toList();
//
//     for (final key in expiredKeys) {
//       _cache.remove(key);
//     }
//   }
//
//   void dispose() {
//     _cleanupTimer?.cancel();
//   }
// }
//
// class _CachedValue<V> {
//   final DateTime timestamp;
//   final V value;
//
//   _CachedValue(this.timestamp, this.value);
// }
