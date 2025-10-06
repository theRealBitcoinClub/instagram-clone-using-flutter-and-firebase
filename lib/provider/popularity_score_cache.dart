// Add this to post_cache_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/provider/isar_provider.dart';
import 'package:mahakka/provider/post_update_provider.dart';
import 'package:mahakka/provider/user_provider.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../memo/model/memo_model_user.dart';

final popularityScoreCacheProvider = Provider((ref) => PopularityScoreCache(ref));

class PopularityScoreCache {
  final Ref ref;

  PopularityScoreCache(this.ref) {
    print('🔄 PSC: PopularityScoreCache constructor called');
  }

  final scoreCache = <String, int>{};
  final _lastUpdateTimes = <String, DateTime>{};
  static const Duration _maxCacheAge = Duration(minutes: 15);

  int? getFromPopularityCache(String postId) {
    final lastUpdate = _lastUpdateTimes[postId];
    if (lastUpdate == null || DateTime.now().difference(lastUpdate) > _maxCacheAge) {
      scoreCache.remove(postId);
      _lastUpdateTimes.remove(postId);
      return null;
    }
    return scoreCache[postId];
  }

  void putInPopularityCache(String postId, int score) {
    scoreCache[postId] = score;
    _lastUpdateTimes[postId] = DateTime.now();
  }

  Future<void> updatePopularityScore(String postId, {int tipAmount = 0, MemoModelPost? scrapedPost, bool saveToFirebase = false}) async {
    print('📊 PSC: updatePopularityScore called for post: $postId');

    // Get ALL cached posts with this postId (both feed and profile)
    final posts = await _getAllPostsById(postId);
    if (posts.isEmpty) {
      print('❌ PSC: Post not found for popularity update: $postId');
      return;
    }

    final TipReceiver receiver = ref.read(userProvider)!.tipReceiver;
    if (receiver == TipReceiver.app) {
      print('ℹ️ PSC: Receiver is app, skipping popularity update');
      return;
    }

    final (int burnAmount, int creatorAmount) = receiver.calculateAmounts(tipAmount);
    final int creatorTipAmount = creatorAmount;

    // Update all found posts (both feed and profile instances)
    for (final post in posts) {
      int newScore;
      if (scrapedPost == null) {
        print("⚠️ PSC: UPDATE POPULARITY FETCH UP TO DATE SCORE FAILED");
        newScore = post.popularityScore + creatorTipAmount;
      } else {
        newScore = scrapedPost.popularityScore + creatorTipAmount;
      }

      print('📊 PSC: Updating popularity score from ${post.popularityScore} to $newScore for postType: ${post.postType}');

      putInPopularityCache(postId, newScore);

      final updatedPost = post.copyWith(popularityScore: newScore);
      await _updatePostInDatabase(updatedPost);

      ref.read(postPopularityProvider.notifier).updatePopularityScore(postId, newScore);
    }
    print('✅ PSC: Popularity score update completed for post: $postId');
  }

  // --- Optimized Post Retrieval with Composite Index ---

  /// Get ALL posts with the given postId (both feed and profile types)
  /// Uses composite index for efficient lookup
  Future<List<MemoModelPost>> _getAllPostsById(String postId) async {
    print('🔍 PSC: _getAllPostsById called for: $postId');

    final isar = await ref.read(unifiedIsarProvider.future);

    // This query uses the composite index for postId lookup
    // Returns both feed and profile posts with the same postId
    final postsDb = await isar.memoModelPostDbs
        .where()
        .postIdEqualToAnyPostType(postId) // Uses composite index, returns both types
        .findAll();

    if (postsDb.isNotEmpty) {
      print('💾 PSC: Found ${postsDb.length} posts in disk cache: $postId');
      return postsDb.map((db) => _enhancePostWithLatestPopularity(db.toAppModel())).toList();
    }

    print('❌ PSC: Post not found in cache: $postId');
    return [];
  }

  /// Update a specific post in the database using composite key
  Future<void> _updatePostInDatabase(MemoModelPost post) async {
    if (post.id == null) {
      print('❌ PSC: Cannot update post with null ID');
      return;
    }

    if (post.postType == null) {
      print('🚨 PSC: CRITICAL - postType is null for post ${post.id}. This should never happen!');
      throw StateError('Post type must be set for database operations. Post: ${post.id}');
    }

    final isar = await ref.read(unifiedIsarProvider.future);

    try {
      await isar.writeTxn(() async {
        // Find the exact post using composite lookup (postId + postType)
        final existingPost = await isar.memoModelPostDbs.where().postIdPostTypeEqualTo(post.id!, post.postType!).findFirst();

        if (existingPost != null) {
          final updatedDb = MemoModelPostDb.fromAppModel(
            post,
            postType: PostTypes.fromId(post.postType!), // Guaranteed to be non-null
          )..id = existingPost.id; // CRITICAL: Preserve the database ID;

          await isar.memoModelPostDbs.put(updatedDb);
          print('💾 PSC: Updated post in database: ${post.id} (type: ${post.postType})');
        } else {
          print('⚠️ PSC: Post not found for update: ${post.id} (type: ${post.postType})');
        }
      });
    } catch (e) {
      print('❌ PSC: Failed to update post in database: $e');
      rethrow; // Let the error propagate for proper error handling
    }
  }

  /// Enhance post with latest popularity score from memory cache
  MemoModelPost _enhancePostWithLatestPopularity(MemoModelPost post) {
    if (post.id == null) return post;

    final latestScore = getFromPopularityCache(post.id!);
    if (latestScore != null && latestScore != post.popularityScore) {
      print('📊 PSC: Enhancing post ${post.id} with latest popularity: $latestScore');
      return post.copyWith(popularityScore: latestScore);
    }
    return post;
  }
}
