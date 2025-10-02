// providers/scraper_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memo/scraper/memo_scraper_tag.dart';
import '../memo/scraper/memo_scraper_topics.dart';

final backgroundScraperManagerProvider = AsyncNotifierProvider<BackgroundScraperManager, void>(() => BackgroundScraperManager());

class BackgroundScraperManager extends AsyncNotifier<void> {
  Timer? _scraperTimer;
  final Duration _initialDelay = Duration(seconds: 30);
  final Duration _scrapeInterval = kDebugMode ? Duration(hours: 3) : Duration(seconds: 60);

  static const String _lastScrapeKey = 'last_scrape_timestamp';
  late SharedPreferences _prefs;

  @override
  Future<void> build() async {
    print("BackgroundScraper: Initializing and starting timer.");

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Check if we should run scraping based on last scrape time
    if (_shouldRunScraping()) {
      _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
        _runScrapingProcess();
      });

      Timer(_initialDelay, () => _runScrapingProcess());
    } else {
      print("BackgroundScraper: Skipping initial scrape - recently completed.");

      // Still set up the timer for future runs
      _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
        _runScrapingProcess();
      });
    }

    ref.onDispose(() {
      _scraperTimer?.cancel();
      print("BackgroundScraper: Timer disposed.");
    });
  }

  /// Checks if scraping should run based on the last scrape time
  bool _shouldRunScraping() {
    final lastScrapeTimestamp = _prefs.getInt(_lastScrapeKey);
    if (lastScrapeTimestamp == null) {
      // Never scraped before, so we should run
      return true;
    }

    final lastScrapeTime = DateTime.fromMillisecondsSinceEpoch(lastScrapeTimestamp);
    final now = DateTime.now();
    final timeSinceLastScrape = now.difference(lastScrapeTime);

    // Only run if the last scrape was more than half the interval ago
    // This prevents frequent scraping on app restarts
    return timeSinceLastScrape > Duration(seconds: _scrapeInterval.inSeconds ~/ 2);
  }

  /// Updates the last scrape timestamp in SharedPreferences
  Future<void> _updateLastScrapeTime() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt(_lastScrapeKey, now);
    print("BackgroundScraper: Updated last scrape time to ${DateTime.now()}");
  }

  /// Gets the last scrape time as DateTime, returns null if never scraped
  DateTime? getLastScrapeTime() {
    final timestamp = _prefs.getInt(_lastScrapeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Manually triggers a scrape and resets the timer.
  Future<void> triggerManualScrape() async {
    _scraperTimer?.cancel();

    await _runScrapingProcess();

    _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
      _runScrapingProcess();
    });
  }

  /// The main scraping logic.
  Future<void> _runScrapingProcess() async {
    // Check if we should run scraping before starting
    if (!_shouldRunScraping()) {
      print("BackgroundScraper: Skipping scrape - recently completed.");
      return;
    }

    state = const AsyncValue.loading();
    print("BackgroundScraper: Starting scraping process...");

    try {
      bool saveToFirebase = true;
      bool deepScrape = false;
      var cacheId = "letsgonownew";

      if (kDebugMode) {
        try {
          await MemoScraperTopic(ref, saveToFirebase).startScrapeTopics(cacheId + "topics", deepScrape ? 100 : 0, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TOPIC scraping: $e");
        }
        try {
          await MemoScraperTag(cacheId + "recent", ref, saveToFirebase).startScrapeTags(["/recent"], deepScrape ? 200 : 25, 0);
          await MemoScraperTag(cacheId + "most", ref, saveToFirebase).startScrapeTags(["/most-posts"], deepScrape ? 200 : 0, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TAG scraping: $e");
        }
      } else {
        try {
          await MemoScraperTopic(ref, false).startScrapeTopics(cacheId + "topics", 0, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TOPIC scraping: $e");
        }
        try {
          await MemoScraperTag(cacheId + "recent", ref, false).startScrapeTags(["/recent"], 25, 0);
        } catch (e) {
          print("BackgroundScraper: An error occurred during TAG scraping: $e");
        }
      }

      // Update last scrape time only on successful completion
      await _updateLastScrapeTime();
      state = const AsyncValue.data(null);
      print("BackgroundScraper: Scraping process completed.");
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      print("BackgroundScraper: An error occurred during scraping: $e");
    }
  }
}
