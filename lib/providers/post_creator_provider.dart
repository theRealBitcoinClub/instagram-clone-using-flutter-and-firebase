// providers/post_creator_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/repositories/creator_repository.dart';

final postCreatorProvider = FutureProvider.family<MemoModelCreator?, String>((ref, creatorId) async {
  // Use the repository to get the creator. The repository handles the caching logic.
  return ref.read(creatorRepositoryProvider).getCreator(creatorId);
});

final settingsCreatorProvider = FutureProvider.family<MemoModelCreator?, String>((ref, creatorId) async {
  // Use the repository to get the creator. The repository handles the caching logic.
  return ref.read(creatorRepositoryProvider).getCreator(creatorId, forceScrape: false, saveToFirebase: false, useCache: true);
});
