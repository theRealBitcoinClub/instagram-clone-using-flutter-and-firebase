import 'dart:async'; // For Future.wait and potentially Completer if needed elsewhere

import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart'; // Assuming MemoModelCreator is defined here

const log_prefix = "MemoCreatorService ";

// Helper for logging - replace with your preferred logging solution
void _logInfo(String message) => print('${log_prefix}INFO: $message');
void _logWarning(String message) => print('${log_prefix}WARNING: $message');
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('${log_prefix}ERROR: $message');
  if (error != null) {
    print('${log_prefix}  Error: $error');
  }
  if (stackTrace != null) {
    print('${log_prefix}  StackTrace: $stackTrace');
  }
}

class MemoCreatorService {
  // Renamed for clarity on its purpose
  static const String _profileIdPrefix = "profile/";
  static const String _rootParserParent = "_root";

  // --- Configuration Methods ---

  ScraperConfig _buildCreatorDetailsConfig() {
    return ScraperConfig(
      parsers: [
        Parser(id: "nameAndText", parents: [_rootParserParent], type: ParserType.text, selectors: [".title"]),
      ],
    );
  }

  ScraperConfig _buildCreatorsListConfig() {
    return ScraperConfig(
      parsers: [
        Parser(id: "users", parents: [_rootParserParent], type: ParserType.element, selectors: ["tr"], multiple: true),
        Parser(id: "id", parents: ["users"], type: ParserType.attribute, selectors: ["a::href"]),
        Parser(multiple: true, id: "stats", parents: ["users"], type: ParserType.text, selectors: ["td"]),
      ],
    );
  }

  // --- Core Scraping Logic ---

  /// Fetches and processes creators based on a list of ordering criteria.
  Future<List<MemoModelCreator>> fetchAndProcessCreators(List<String> orderByCriteria) async {
    final List<MemoModelCreator> allProcessedCreators = [];

    for (String order in orderByCriteria) {
      _logInfo("Starting to scrape creators ordered by: $order");
      try {
        List<MemoModelCreator> initialCreators = await _fetchCreatorList(order);
        if (initialCreators.isEmpty) {
          _logWarning("No creators found for order: $order");
          continue;
        }

        // Fetch details concurrently
        final List<MemoModelCreator?> detailedCreators = await Future.wait(
          initialCreators.map((creator) async {
            try {
              return await fetchCreatorDetails(creator);
            } catch (e, s) {
              _logError("Failed to load details for creator ${creator.id}", e, s);
              return null; // Return null if fetching details for one creator fails
            }
          }).toList(),
        );

        // Filter out nulls (failed detail fetches) and add to the main list
        allProcessedCreators.addAll(detailedCreators.whereType<MemoModelCreator>());
        _logInfo(
          "Successfully processed ${detailedCreators.whereType<MemoModelCreator>().length} creators for order: $order",
        );
      } catch (e, s) {
        _logError("Failed to scrape or process creators for order: $order", e, s);
        // Depending on requirements, you might want to:
        // - throw e; // to stop all processing
        // - continue; // to try the next order
      }
    }
    _logInfo("Finished processing all order criteria. Total creators fetched: ${allProcessedCreators.length}");
    return allProcessedCreators;
  }

  /// Fetches the initial list of creators with basic information.
  Future<List<MemoModelCreator>> _fetchCreatorList(String sortedBy) async {
    _logInfo("Fetching creator list sorted by: $sortedBy");
    final Map<String, Object> scrapedData = await MemoScraperUtil.createScraper(
      "profiles$sortedBy", // Assuming no slash needed before sortedBy
      _buildCreatorsListConfig(),
    );

    if (scrapedData.values.isEmpty) {
      _logWarning("No data returned from scraper for creator list (sortedBy: $sortedBy).");
      return [];
    }

    final dynamic rawItems = scrapedData.values.first;
    if (rawItems is! List) {
      _logWarning("Expected a List from scraper for creator list, but got ${rawItems.runtimeType}.");
      return [];
    }

    final List<MemoModelCreator> creators = [];
    for (final dynamic itemUntyped in rawItems) {
      if (itemUntyped is! Map<String, Object?>) {
        _logWarning(
          "Expected item in creator list to be a Map, but got ${itemUntyped.runtimeType}. Item: $itemUntyped",
        );
        continue;
      }
      final Map<String, Object?> item = itemUntyped;

      final String? idRaw = item["id"]?.toString();
      if (idRaw == null || !idRaw.startsWith(_profileIdPrefix)) {
        _logWarning("Invalid or missing 'id' for item: $item");
        continue;
      }
      final String id = idRaw.substring(_profileIdPrefix.length);

      final dynamic statsRaw = item["stats"];
      if (statsRaw is! List || statsRaw.any((s) => s is! String) || statsRaw.length < 5) {
        _logWarning("'stats' data is invalid or incomplete for item with id $id. Stats: $statsRaw");
        continue;
      }
      final List<String> stats = statsRaw.cast<String>();

      // Helper for parsing stats, could be a static method or local function
      int? tryParseStat(String value) => int.tryParse(value.replaceAll(",", ""));

      creators.add(
        MemoModelCreator(
          id: id,
          // Assuming MemoModelCreator constructor handles nulls or has defaults
          followerCount: tryParseStat(stats[2]) ?? 0,
          actions: tryParseStat(stats[1]) ?? 0,
          created: stats[3], // Assuming these are always present if stats.length >= 5
          lastActionDate: stats[4],
          // name and profileText will be filled by _fetchCreatorDetails
        ),
      );
    }
    _logInfo("Found ${creators.length} initial creators for sortedBy: $sortedBy");
    return creators;
  }

  /// Fetches and updates a single creator with their name and profile text.
  Future<MemoModelCreator> fetchCreatorDetails(MemoModelCreator creator, {bool noCache = false}) async {
    _logInfo("Fetching details for creator ID: ${creator.id}");
    final Map<String, Object> data = await MemoScraperUtil.createScraper(
      "profile/${creator.id}",
      _buildCreatorDetailsConfig(),
      nocache: noCache, // Corrected parameter name
    );

    if (data.values.isEmpty || data.values.first is! String) {
      _logWarning("No valid string data returned from scraper for creator details (ID: ${creator.id}).");
      // Return creator as is, or throw an error if name/text are critical
      return creator;
    }

    final String rawText = data.values.first as String;
    final List<String> lines = rawText.split("\n")..removeWhere((element) => element.trim().isEmpty);

    if (lines.isNotEmpty) {
      creator.name = lines[0].trim();
    } else {
      _logWarning("Name not found for creator ID: ${creator.id}. Raw text: $rawText");
      // creator.name = "Unknown Name"; // Or keep as is, depending on MemoModelCreator design
    }

    if (lines.length > 1) {
      creator.profileText = lines[1].trim();
    } else {
      _logWarning("Profile text not found for creator ID: ${creator.id}. Raw text: $rawText");
      // creator.profileText = ""; // Or keep as is
    }
    _logInfo("Successfully fetched details for creator ID: ${creator.id}");
    return creator; // Return the mutated creator
  }
}

// --- Assumptions for MemoModelCreator ---
// class MemoModelCreator {
//   final String id;
//   String? name;
//   String? profileText;
//   int? followerCount;
//   int? actions;
//   String? created;
//   String? lastActionDate;

//   MemoModelCreator({
//     required this.id,
//     this.name,
//     this.profileText,
//     this.followerCount,
//     this.actions,
//     this.created,
//     this.lastActionDate,
//   });

//   @override
//   String toString() {
//     return 'MemoModelCreator(id: $id, name: $name, followers: $followerCount, actions: $actions)';
//   }
// }
