// repositories/creator_cache_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

class CreatorCacheRepository {
  final Ref ref;

  // The in-memory cache for fast, session-based lookups
  final Map<String, MemoModelCreator> _inMemoryCache = {};

  CreatorCacheRepository(this.ref);

  /// Gets a creator from the in-memory cache first, then from Isar.
  Future<MemoModelCreator?> getCreatorFromCache(String creatorId) async {
    // Layer 1: Check in-memory cache
    if (_inMemoryCache.containsKey(creatorId)) {
      print("INFO: Fetched creator $creatorId from in-memory cache.");
      return _inMemoryCache[creatorId];
    }

    return null;
  }

  /// Saves a creator to both Isar and the in-memory cache.
  Future<void> saveToCache(MemoModelCreator creator) async {
    print("INFO: Saved creator ${creator.id} to Isar cache.");

    // Save to in-memory cache
    _inMemoryCache[creator.id] = creator;
    print("INFO: Saved creator ${creator.id} to in-memory cache.");
  }
}

final creatorCacheRepositoryProvider = Provider((ref) => CreatorCacheRepository(ref));
