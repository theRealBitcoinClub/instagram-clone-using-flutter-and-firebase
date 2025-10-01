// Add this to post_cache_repository.dart
class PopularityScoreCache {
  static final PopularityScoreCache _instance = PopularityScoreCache._internal();
  factory PopularityScoreCache() => _instance;
  PopularityScoreCache._internal();

  final scoreCache = <String, int>{};
  final _lastUpdateTimes = <String, DateTime>{};
  static const Duration _maxCacheAge = Duration(minutes: 15);

  int? get(String postId) {
    final lastUpdate = _lastUpdateTimes[postId];
    if (lastUpdate == null || DateTime.now().difference(lastUpdate) > _maxCacheAge) {
      scoreCache.remove(postId);
      _lastUpdateTimes.remove(postId);
      return null;
    }
    return scoreCache[postId];
  }

  void put(String postId, int score) {
    scoreCache[postId] = score;
    _lastUpdateTimes[postId] = DateTime.now();
  }

  void remove(String postId) {
    scoreCache.remove(postId);
    _lastUpdateTimes.remove(postId);
  }

  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = _lastUpdateTimes.entries
        .where((entry) => now.difference(entry.value) > _maxCacheAge)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      scoreCache.remove(key);
      _lastUpdateTimes.remove(key);
    }
  }
}
