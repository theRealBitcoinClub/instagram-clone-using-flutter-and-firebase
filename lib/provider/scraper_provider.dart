// providers/scraper_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/update_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../memo/scraper/memo_scraper_tag.dart';
import '../memo/scraper/memo_scraper_topics.dart';

final backgroundScraperManagerProvider = AsyncNotifierProvider<BackgroundScraperManager, void>(() => BackgroundScraperManager());

const bool forceScrape = false;
const bool saveToFirebase = true;
const bool deepScrape = false;
const cacheId = "letsgonownew";

class BackgroundScraperManager extends AsyncNotifier<void> {
  Timer? _scraperTimer;
  final Duration _initialDelay = Duration(seconds: 15);
  final Duration _scrapeInterval = kDebugMode && !forceScrape ? Duration(hours: 3) : Duration(seconds: 120);
  final bool _debugMode = kDebugMode;

  static const String _lastScrapeKey = 'last_scrape_timestamp';
  late SharedPreferences _prefs;

  @override
  Future<void> build() async {
    _print("BGS: 🚀 Initializing and starting timer! 🎯");

    // Initialize SharedPreferences
    _prefs = ref.read(sharedPreferencesProvider);
    bool needsToUpdate = ref.watch(updateInfoProvider).isUpdateAvailable;

    // Check if we should run scraping based on last scrape time
    if (_shouldRunScraping() && !needsToUpdate) {
      _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
        _runScrapingProcess();
      });

      Timer(_initialDelay, () => _runScrapingProcess());
    } else {
      Sentry.logger.debug("BGS: ⏭️ Skipping initial scrape - recently completed! 📅 or needs to update: $needsToUpdate");
      _print("BGS: ⏭️ Skipping initial scrape - recently completed! 📅 or needs to update: $needsToUpdate");

      // Still set up the timer for future runs
      _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
        _runScrapingProcess();
      });
    }

    ref.onDispose(() {
      _scraperTimer?.cancel();
      _print("BGS: 🛑 Timer disposed! 👋");
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
    _print("BGS: 📝 Updated last scrape time to ${DateTime.now()} 🕒");
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

  bool isScraping = false;

  /// The main scraping logic.
  Future<void> _runScrapingProcess() async {
    // Check if we should run scraping before starting
    if (!_shouldRunScraping()) {
      _print("BGS: ⏭️ Skipping scrape - recently completed! 📅");
      return;
    }
    if (isScraping) {
      _print("BGS: ⏭️ Skipping scrape - its still running!");
      return;
    }
    isScraping = true;

    state = const AsyncValue.loading();
    _print("BGS: 🚀 Starting scraping process... 🎣");

    try {
      if (_debugMode) {
        try {
          await MemoScraperTopic(ref, saveToFirebase).startScrapeTopics(cacheId + "topics", deepScrape ? 200 : 0, 0);
        } catch (e) {
          _print("BGS: ❌ An error occurred during TOPIC scraping: $e 🚨");
        }
        try {
          await MemoScraperTag(cacheId + "recent", ref, saveToFirebase).startScrapeTags(["/recent"], deepScrape ? 400 : 100, 0);
          await MemoScraperTag(cacheId + "most", ref, saveToFirebase).startScrapeTags(["/most-posts"], deepScrape ? 400 : 0, 0);
        } catch (e) {
          _print("BGS: ❌ An error occurred during TAG scraping: $e 🚨");
        }
      } else {
        try {
          await MemoScraperTopic(ref, saveToFirebase).startScrapeTopics(cacheId + "topics", 0, 0);
        } catch (e) {
          _print("BGS: ❌ An error occurred during TOPIC scraping: $e 🚨");
        }
        try {
          await MemoScraperTag(cacheId + "recent", ref, saveToFirebase).startScrapeTags(["/recent"], 100, 0);
        } catch (e) {
          _print("BGS: ❌ An error occurred during TAG scraping: $e 🚨");
        }
      }

      // Update last scrape time only on successful completion
      await _updateLastScrapeTime();
      state = const AsyncValue.data(null);
      _print("BGS: ✅ Scraping process completed! 🎉");
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      _print("BGS: ❌ An error occurred during scraping: $e 🚨");
    } finally {
      isScraping = false;
    }
  }

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}
