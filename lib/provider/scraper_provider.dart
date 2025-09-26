// providers/scraper_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memo/scraper/memo_scraper_tag.dart';
import '../memo/scraper/memo_scraper_topics.dart';

// The AsyncNotifierProvider is the ideal provider for asynchronous state management.
final backgroundScraperManagerProvider = AsyncNotifierProvider<BackgroundScraperManager, void>(() => BackgroundScraperManager());

class BackgroundScraperManager extends AsyncNotifier<void> {
  Timer? _scraperTimer;
  Duration _initialDelay = Duration(seconds: 10);
  Duration _scrapeInterval = Duration(seconds: kDebugMode ? 300 : 10);

  @override
  Future<void> build() async {
    // This method is called once when the provider is first accessed.
    // It's the perfect place to start the periodic task.
    print("BackgroundScraper: Initializing and starting timer.");

    // The timer is set up to run the scraping process periodically.
    _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
      _runScrapingProcess();
    });

    // We can also run the first scrape immediately after a delay.
    Timer(_initialDelay, () => _runScrapingProcess());

    // Use onDispose to clean up the timer, ensuring no memory leaks.
    ref.onDispose(() {
      _scraperTimer?.cancel();
      print("BackgroundScraper: Timer disposed.");
    });
  }

  /// Manually triggers a scrape and resets the timer.
  Future<void> triggerManualScrape() async {
    // Cancel the old timer to prevent overlapping runs.
    _scraperTimer?.cancel();

    // Immediately run the scraping process and wait for it to complete.
    await _runScrapingProcess();

    // Restart the periodic timer.
    _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
      _runScrapingProcess();
    });
  }

  /// The main scraping logic.
  Future<void> _runScrapingProcess() async {
    // Update the provider's state to loading to indicate the process has started.
    state = const AsyncValue.loading();
    print("BackgroundScraper: Starting scraping process...");
    print("BackgroundScraper: Starting scraping process...");
    print("BackgroundScraper: Starting scraping process...");
    print("BackgroundScraper: Starting scraping process...");
    print("BackgroundScraper: Starting scraping process...");

    try {
      // Execute the scraping tasks.
      var cacheId = "letsgo";
      await MemoScraperTopic().startScrapeTopics(cacheId + "topics", 200, 0);
      await MemoScraperTag(cacheId + "recent").startScrapeTags(["/recent"], 200, 0);
      await MemoScraperTag(cacheId + "most").startScrapeTags(["/most-posts"], 200, 0);
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 50, 50);P
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 0, 0);
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 0, 0);
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 0, 0);

      // If the process succeeds, update the state to data with a null value.
      state = const AsyncValue.data(null);
      print("BackgroundScraper: Scraping process completed.");
      print("BackgroundScraper: Scraping process completed.");
      print("BackgroundScraper: Scraping process completed.");
      print("BackgroundScraper: Scraping process completed.");
      print("BackgroundScraper: Scraping process completed.");
    } catch (e, s) {
      // If an error occurs, update the state to error.
      state = AsyncValue.error(e, s);
      print("BackgroundScraper: An error occurred during scraping: $e");
    }
  }
}
