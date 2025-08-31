// providers/scraper_provider.dart
// The file where you want to implement the background process, e.g., a stateful widget's state class.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memo/scraper/memo_scraper_tag.dart';
import '../memo/scraper/memo_scraper_topics.dart';

// This is the correct way to define a provider. It receives a generic Ref.
final backgroundScraperManagerProvider = Provider<BackgroundScraperManager>((ref) {
  // Here, you can pass the Ref to the class constructor.
  return BackgroundScraperManager(ref);
});

class BackgroundScraperManager extends StateNotifier<bool> {
  final Ref ref;
  Timer? _scraperTimer;
  final Duration _initialDelay = const Duration(seconds: 10);
  final Duration _scrapeInterval = const Duration(minutes: 1);

  BackgroundScraperManager(this.ref) : super(false) {
    // Start the process immediately when the provider is created
    _startScraping();
  }

  void _startScraping() {
    _scraperTimer = Timer(_initialDelay, () {
      _runScrapingProcess();
      _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
        _runScrapingProcess();
      });
    });
  }

  Future<void> triggerManualScrape() async {
    // Cancel the old timer to prevent overlapping runs.
    _scraperTimer?.cancel();
    _runScrapingProcess();

    // Restart the periodic timer after the manual run.
    _scraperTimer = Timer.periodic(_scrapeInterval, (timer) {
      _runScrapingProcess();
    });
  }

  /// The main scraping logic.
  Future<void> _runScrapingProcess() async {
    print("BackgroundScraper: Starting scraping process...");
    // final creatorRepo = ref.read(creatorRepositoryProvider);

    var cacheId = "AX";
    try {
      await MemoScraperTopic().startScrapeTopics([], cacheId, 0, 0);
      await MemoScraperTag().startScrapeTags(["/recent"], 0, 0, cacheId);
    } catch (e) {
      print("BACKGROUNDSCRAPER ERROR:" + e.toString());
    }
    // try {
    //   // You'll need a way to get the list of creators to scrape.
    //   // For example, from a local cache or a list of followed creators.
    //   // This is a placeholder for how you would get the list of IDs.
    //   final List<String> creatorIdsToScrape = ['your-creator-id-1', 'your-creator-id-2'];
    //
    //   for (String id in creatorIdsToScrape) {
    //     // Use the repository to get the latest data.
    //     // The repository handles the cache and network logic for you.
    //     final MemoModelCreator? creator = await creatorRepo.getCreator(id);
    //     if (creator != null) {
    //       print("BackgroundScraper: Scraped and updated data for creator ${creator.name} ($id).");
    //       // The repository methods already handle saving to Firebase and caching.
    //     }
    //   }
    //   print("BackgroundScraper: Scraping process completed.");
    // } catch (e, s) {
    //   print("BackgroundScraper: An error occurred during scraping: $e");
    //   print(s);
    // }
  }

  /// Disposes of the timer to prevent memory leaks when the widget is removed.
  void dispose() {
    _scraperTimer?.cancel();
    _scraperTimer = null;
    print("BackgroundScraper: Timer disposed.");
    super.dispose();
  }
}
