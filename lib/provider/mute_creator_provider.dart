// mute_creator_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memo/model/memo_model_creator.dart';
import '../repositories/creator_repository.dart';
import 'feed_posts_provider.dart';

final muteCreatorProvider = StateNotifierProvider<MuteCreatorNotifier, List<String>>((ref) {
  return MuteCreatorNotifier(ref);
});

// New async provider that loads creator objects
final mutedCreatorsWithDetailsProvider = FutureProvider<List<MemoModelCreator>>((ref) async {
  final mutedCreatorIds = ref.watch(muteCreatorProvider);
  final creatorRepository = ref.read(creatorRepositoryProvider);

  final List<MemoModelCreator> creators = [];

  for (final creatorId in mutedCreatorIds) {
    try {
      final creator = await creatorRepository.getCreator(creatorId);
      if (creator != null) {
        creators.add(creator);
      }
    } catch (e) {
      print('❌ Failed to load creator $creatorId: $e');
      // Continue with other creators even if one fails
    }
  }

  return creators;
});

class MuteCreatorNotifier extends StateNotifier<List<String>> {
  MuteCreatorNotifier(this.ref) : super(["fakeId"]);
  static const String _mutedCreatorsKey = 'muted_creators';
  bool _isInitialized = false;
  Ref ref;

  // Call this during app initialization - must be called before using the provider
  Future<void> initialize(SharedPreferences prefs) async {
    if (_isInitialized) {
      print('ℹ️ MuteCreator: Already initialized');
      return;
    }

    try {
      final mutedCreators = prefs.getStringList(_mutedCreatorsKey) ?? [];
      state = mutedCreators;
      _isInitialized = true;
      print('✅ MuteCreator: Initialized with ${mutedCreators.length} muted creators');
    } catch (e) {
      print('❌ MuteCreator: Failed to initialize muted creators: $e');
      state = [];
      _isInitialized = true; // Mark as initialized even on error to prevent repeated attempts
    }
  }

  // Mute a creator
  Future<void> muteCreator(String creatorId, {Function()? onMuteSuccess, Function()? onMutedAlready}) async {
    if (state.contains(creatorId)) {
      onMutedAlready?.call();
      return; // Already muted
    }

    try {
      final newMutedCreators = [...state, creatorId];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_mutedCreatorsKey, newMutedCreators);
      state = newMutedCreators;
      // ref.read(feedPostCacheProvider).resetLoadedItems();
      ref.read(feedPostsProvider.notifier).fetchInitialPosts();
      onMuteSuccess?.call();
      print('✅ MuteCreator: Muted creator: $creatorId');
    } catch (e) {
      print('❌ MuteCreator: Failed to mute creator: $e');
      throw Exception('Failed to mute creator');
    }
  }

  // Unmute a creator
  Future<void> unmuteCreator(String creatorId) async {
    if (!state.contains(creatorId)) {
      return; // Not muted
    }

    try {
      final newMutedCreators = state.where((id) => id != creatorId).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_mutedCreatorsKey, newMutedCreators);
      state = newMutedCreators;
      // ref.read(feedPostCacheProvider).resetLoadedItems();
      ref.read(feedPostsProvider.notifier).fetchInitialPosts();
      print('✅ MuteCreator: Unmuted creator: $creatorId');
    } catch (e) {
      print('❌ MuteCreator: Failed to unmute creator: $e');
      throw Exception('Failed to unmute creator');
    }
  }

  // Check if a creator is muted
  bool isCreatorMuted(String creatorId) {
    return state.contains(creatorId);
  }

  // Get all muted creators
  List<String> get mutedCreators => state;

  // Check if provider has been initialized
  bool get isInitialized => _isInitialized;
}
