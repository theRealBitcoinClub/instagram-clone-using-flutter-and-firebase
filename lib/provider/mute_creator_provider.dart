// mute_creator_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../memo/model/memo_model_creator.dart';
import '../repositories/creator_repository.dart';
import 'feed_posts_provider.dart';

final muteCreatorProvider = StateNotifierProvider<MuteCreatorNotifier, List<String>>((ref) {
  return MuteCreatorNotifier(ref);
});
// Add this provider
final muteCreatorInitializerProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(userProvider);
  final prefs = ref.read(sharedPreferencesProvider);

  if (user != null) {
    Future.microtask(() {
      ref.read(muteCreatorProvider.notifier).initialize(prefs, user.id);
    });
  }
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
  Future<void> initialize(SharedPreferences prefs, String userId) async {
    if (_isInitialized) {
      print('ℹ️ MuteCreator: Already initialized');
      return;
    }

    try {
      final mutedCreators = prefs.getStringList(_mutedCreatorsKey + userId) ?? [];
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
  Future<void> muteCreator(String creatorId, {Function()? onMuteSuccess, Function()? onMuteLimitReached}) async {
    if (state.contains(creatorId)) {
      return; // Already muted
    }
    String userId = ref.read(userProvider)!.id;

    try {
      final newMutedCreators = [...state, creatorId];

      TokenLimitEnum tokenLimitEnum = ref.read(currentTokenLimitEnumProvider);
      if (tokenLimitEnum.muteLimit < newMutedCreators.length) {
        ref.read(snackbarServiceProvider).showTranslatedSnackBar(tokenLimitEnum.muteLimitText, type: SnackbarType.error);
        onMuteLimitReached?.call();
        return;
      }

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_mutedCreatorsKey + userId, newMutedCreators);

      state = newMutedCreators;
      ref.read(feedPostsProvider.notifier).fetchInitialPosts();
      ref.read(snackbarServiceProvider).showTranslatedSnackBar("Feed updated, mute filter applied", type: SnackbarType.success);
      onMuteSuccess?.call();
      print('✅ MuteCreator: Muted creator: $creatorId');
    } catch (e) {
      print('❌ MuteCreator: Failed to mute creator: $e');
      throw Exception('Failed to mute creator');
    }
  }

  // Debounce timer for unmute operations
  Timer? _unmuteDebounceTimer;

  // Unmute a creator
  Future<void> unmuteCreator(String creatorId) async {
    if (!state.contains(creatorId)) {
      return; // Not muted
    }
    String userId = ref.read(userProvider)!.id;

    try {
      final newMutedCreators = state.where((id) => id != creatorId).toList();
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_mutedCreatorsKey + userId, newMutedCreators);
      state = newMutedCreators;

      _unmuteDebounceTimer?.cancel();
      _unmuteDebounceTimer = Timer(const Duration(seconds: 6), () {
        ref.read(feedPostsProvider.notifier).fetchInitialPosts(forceFetchFire: true);
        ref.read(snackbarServiceProvider).showTranslatedSnackBar("Updating feed, applieng mute filter", type: SnackbarType.success);
        print('🔄 MuteCreator: Debounced feed refresh triggered after unmute');
      });

      print('✅ MuteCreator: Unmuted creator: $creatorId (feed refresh scheduled in 6 seconds)');
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
