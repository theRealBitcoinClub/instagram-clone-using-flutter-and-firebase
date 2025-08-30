// providers/creator_cache_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

// Provides an in-memory cache for MemoModelCreator objects.
// The key is the creator's ID, and the value is the Creator object.
final creatorCacheProvider = StateProvider<Map<String, MemoModelCreator>>((ref) {
  return {};
});
