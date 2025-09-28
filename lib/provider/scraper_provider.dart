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
  Duration _initialDelay = Duration(seconds: 30);
  Duration _scrapeInterval = kDebugMode ? Duration(hours: 3) : Duration(seconds: 30);

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
    // print("BackgroundScraper: Starting scraping process...");
    // print("BackgroundScraper: Starting scraping process...");
    // print("BackgroundScraper: Starting scraping process...");
    // print("BackgroundScraper: Starting scraping process...");

    try {
      // Execute the scraping tasks.
      bool saveToFirebase = true;
      bool deepScrape = false;
      var cacheId = "letsgonownew";
      //TODO SCRAPER RANDOMLY SELECTS OFFSETS SO THAT DIFFERENT USERS SCRAPE DIFFERENT OFFSETS?
      if (kDebugMode) {
        try {
          await MemoScraperTopic(ref, saveToFirebase).startScrapeTopics(cacheId + "topics", deepScrape ? 50 : 0, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TOPIC scraping: $e");
        }
        try {
          await MemoScraperTag(cacheId + "recent", ref, saveToFirebase).startScrapeTags(["/recent"], deepScrape ? 200 : 25, 0);
          // await MemoScraperTag(cacheId + "most", ref, saveToFirebase).startScrapeTags(["/most-posts"], 100, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TAG scraping: $e");
        }
      } else {
        try {
          await MemoScraperTopic(ref, saveToFirebase).startScrapeTopics(cacheId + "topics", 0, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TOPIC scraping: $e");
        }
        try {
          await MemoScraperTag(cacheId + "recent", ref, saveToFirebase).startScrapeTags(["/recent"], 50, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TAG scraping: $e");
        }
      }
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 50, 50);P
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 0, 0);
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 0, 0);
      // await MemoScraperTag(cacheId).startScrapeTags(["/recent"], 0, 0);

      // If the process succeeds, update the state to data with a null value.
      state = const AsyncValue.data(null);
      print("BackgroundScraper: Scraping process completed.");
      // print("BackgroundScraper: Scraping process completed.");
      // print("BackgroundScraper: Scraping process completed.");
      // print("BackgroundScraper: Scraping process completed.");
      // print("BackgroundScraper: Scraping process completed.");
    } catch (e, s) {
      // If an error occurs, update the state to error.
      state = AsyncValue.error(e, s);
      print("BackgroundScraper: An error occurred during scraping: $e");
    }
  }
}
