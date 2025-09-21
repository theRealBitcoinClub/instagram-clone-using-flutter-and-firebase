import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/scraper/memo_post_scraper.dart';

import '../repositories/post_cache_repository.dart';

// Provider to track popularity score updates for individual posts
final postPopularityProvider = StateNotifierProvider<PostPopularityNotifier, Map<String, int>>((ref) {
  return PostPopularityNotifier(ref);
});

class PostPopularityNotifier extends StateNotifier<Map<String, int>> {
  final Ref ref;
  final Map<String, DateTime> _lastFetchTimes = {};
  final Map<String, Timer> _refreshTimers = {};
  static const Duration refreshInterval = Duration(minutes: 5);

  PostPopularityNotifier(this.ref) : super({});

  // Fetch popularity score for a specific post
  Future<void> fetchPopularityScore(String postId) async {
    // Check if we recently fetched this post
    final lastFetch = _lastFetchTimes[postId];
    if (lastFetch != null && DateTime.now().difference(lastFetch) < refreshInterval) {
      return; // Too soon to fetch again
    }

    try {
      // Execute the scraping
      MemoModelPost? scrapedPost = await MemoPostScraper().fetchAndParsePost(postId, filterOn: false);

      if (scrapedPost != null) {
        // Update the state with the new score
        state = {...state, postId: scrapedPost.popularityScore};

        // Update the cache repository
        ref.read(postCacheRepositoryProvider).updatePopularityScore(postId, scrapedPost: scrapedPost);

        // Record the fetch time
        _lastFetchTimes[postId] = DateTime.now();

        // Schedule next refresh if not already scheduled
        if (!_refreshTimers.containsKey(postId)) {
          _scheduleRefresh(postId);
        }
      }
    } catch (error) {
      print('Error fetching popularity score for post $postId: $error');
      // You might want to retry after a shorter interval on error
    }
  }

  // Schedule automatic refresh for a post
  void _scheduleRefresh(String postId) {
    _refreshTimers[postId] = Timer(refreshInterval, () {
      fetchPopularityScore(postId);
    });
  }

  // Manually update the popularity score
  void updatePopularityScore(String postId, int newScore) {
    state = {...state, postId: newScore};
    _lastFetchTimes[postId] = DateTime.now();

    // Ensure a refresh is scheduled
    if (!_refreshTimers.containsKey(postId)) {
      _scheduleRefresh(postId);
    }
  }

  // Cancel all timers when notifier is disposed
  @override
  void dispose() {
    _refreshTimers.values.forEach((timer) => timer.cancel());
    _refreshTimers.clear();
    super.dispose();
  }
}
