// Add this to post_cache_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/provider/isar_provider.dart';
import 'package:mahakka/provider/post_update_provider.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/profile_post_cache.dart';

import '../memo/isar/memo_model_post_db.dart';
import '../memo/model/memo_model_post.dart';
import '../memo/model/memo_model_user.dart';
import '../repositories/feed_post_cache.dart';

final popularityScoreCacheProvider = Provider((ref) => PopularityScoreCache(ref));

class PopularityScoreCache {
  Ref ref;

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
    MemoModelPost? post = await _getPostWithPopularityScore(postId);
    if (post == null) {
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

    int newScore;
    if (scrapedPost == null) {
      print("⚠️ PSC: UPDATE POPULARITY FETCH UP TO DATE SCORE FAILED");
      newScore = post.popularityScore + creatorTipAmount;
    } else {
      newScore = scrapedPost.popularityScore + creatorTipAmount;
    }

    print('📊 PSC: Updating popularity score from ${post.popularityScore} to $newScore');

    // Update popularity cache (this still needs expiration)
    putInPopularityCache(postId, newScore);

    // Update disk cache - try both feed and profile databases
    final updatedPost = post.copyWith(popularityScore: newScore);
    await ref.read(profilePostCacheProvider).updatePostInProfileDatabase(updatedPost);
    await ref.read(feedPostCacheProvider).updatePostInFeedDatabase(updatedPost);

    ref.read(postPopularityProvider.notifier).updatePopularityScore(postId, newScore);
    print('✅ PSC: Popularity score update completed for post: $postId');
  }

  // --- Post Retrieval with Popularity Score ---

  Future<MemoModelPost?> _getPostWithPopularityScore(String postId) async {
    print('🔍 PPC: _getPostWithPopularityScore called for: $postId');
    MemoModelPostDb? postDb;

    final feedIsar = await ref.read(feedPostsIsarProvider.future);
    postDb = await feedIsar.memoModelPostDbs.where().postIdEqualTo(postId).findFirst();

    if (postDb == null) {
      final profileIsar = await ref.read(profilePostsIsarProvider.future);
      postDb = await profileIsar.memoModelPostDbs.where().postIdEqualTo(postId).findFirst();
    }

    if (postDb != null) {
      print('💾 PPC: Found post in disk cache: $postId');
      final post = postDb.toAppModel();
      // _addToMemoryCache(post);
      return _enhancePostWithLatestPopularity(post);
    }

    print('❌ PPC: Post not found in any cache: $postId');
    return null;
  }

  MemoModelPost _enhancePostWithLatestPopularity(MemoModelPost post) {
    final latestScore = getFromPopularityCache(post.id!);
    if (latestScore != null && latestScore != post.popularityScore) {
      print('📊 PPC: Enhancing post ${post.id} with latest popularity: $latestScore');
      return post.copyWith(popularityScore: latestScore);
    }
    return post;
  }
}
