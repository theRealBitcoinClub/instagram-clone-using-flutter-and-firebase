// providers/creator_avatar_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/repositories/creator_repository.dart';

// This provider fetches and caches only the creator's avatar.
final creatorAvatarProvider = FutureProvider.family<String?, String>((ref, creatorId) async {
  return ref.read(creatorRepositoryProvider).refreshAndCacheAvatar(creatorId);
});
