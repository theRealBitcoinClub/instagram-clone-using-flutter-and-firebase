import 'dart:async'; // For potential future concurrency, though not strictly needed here yet

import 'package:instagram_clone1/dart_web_scraper/common/enums.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/parser_model.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_utils.dart';

import '../memomodel/memo_model_creator.dart';
import '../memomodel/memo_model_post.dart';
import '../memomodel/memo_model_topic.dart';

// Helper for logging - replace with your preferred logging solution
void _logInfo(String message) => print('INFO: $message');
void _logWarning(String message) => print('WARNING: $message');
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: $message');
  if (error != null) {
    print('  Error: $error');
  }
  if (stackTrace != null) {
    print('  StackTrace: $stackTrace');
  }
}

class MemoPostService {
  // Renamed for clarity on its purpose
  static const String _rootParserParent = "_root";
  static const String _txHashPrefix = "/post";
  static const int _profileUrlPrefixLength = 8; // Length of "profile/" is 8, adjust if prefix changes

  // --- Configuration Method ---

  ScraperConfig _buildPostsScraperConfig() {
    return ScraperConfig(
      parsers: [
        Parser(
          id: "posts",
          parents: [_rootParserParent],
          type: ParserType.element,
          selectors: [".post"],
          multiple: true,
        ),
        Parser(id: "msg", parents: ["posts"], type: ParserType.text, selectors: [".message"]),
        Parser(id: "profileUrl", parents: ["posts"], type: ParserType.url, selectors: [".profile"]),
        Parser(id: "age", parents: ["posts"], type: ParserType.text, selectors: [".time-ago"]),
        Parser(id: "tipsInSatoshi", parents: ["posts"], type: ParserType.text, selectors: [".tip-button"]),
        Parser(id: "created", parents: ["posts"], type: ParserType.attribute, selectors: [".time-ago::title"]),
        Parser(id: "txhash", parents: ["posts"], type: ParserType.url, selectors: [".time-ago"]),
        Parser(id: "creatorName", parents: ["posts"], type: ParserType.text, selectors: [".profile"]),
        Parser(id: "imgur", parents: ["posts"], type: ParserType.attribute, selectors: [".imgur::href"]),
        Parser(id: "reply", parents: ["posts"], type: ParserType.text, selectors: [".post-header"]),
        Parser(id: "topic", parents: ["posts"], type: ParserType.text, selectors: [".topic-link"]),
        Parser(
          id: "topicLink",
          parents: ["posts"],
          type: ParserType.attribute,
          selectors: [".topic-link::href"],
        ), // Renamed for clarity from "topic-link"
      ],
    );
  }

  // --- Core Scraping Logic ---

  /// Scrapes posts from a given URL with pagination.
  Future<List<MemoModelPost>> scrapePostsPaginated({
    required String baseUrl,
    required int initialOffset,
    required String cacheId,
    int offsetStep = 25,
  }) async {
    final config = _buildPostsScraperConfig();
    final List<MemoModelPost> allPosts = [];

    _logInfo("Starting post scraping from URL: $baseUrl with initial offset: $initialOffset");

    for (int currentOffset = initialOffset; currentOffset >= 0; currentOffset -= offsetStep) {
      final String scrapeUrl = "$baseUrl?offset=$currentOffset&x=$cacheId";
      _logInfo("Scraping posts from: $scrapeUrl");

      try {
        final Map<String, Object> scrapedData = await MemoScraperUtil.createScraper(scrapeUrl, config);
        final List<MemoModelPost> newPosts = _parseScrapedPostData(scrapedData);

        if (newPosts.isNotEmpty) {
          // Assuming MemoModelPost.addToGlobalPostList is a desired side effect.
          // Consider if this global modification is the best approach or if
          // this service should just return the data.
          MemoModelPost.addToGlobalPostList(newPosts);
          allPosts.addAll(newPosts);
          _logInfo("Successfully scraped and processed ${newPosts.length} posts from offset $currentOffset.");
        } else {
          _logInfo("No new posts found at offset $currentOffset.");
        }
      } catch (e, s) {
        _logError("Failed to scrape posts from $scrapeUrl", e, s);
        // Decide on error strategy:
        // - continue; // to try the next offset (might lead to missed data if temporary issue)
        // - break; // to stop paginating on first error
        // - throw e; // to propagate the error up
        // For now, let's continue to the next offset but log the error.
      }
    }

    _logInfo("Finished scraping posts from base URL: $baseUrl. Total posts fetched: ${allPosts.length}");
    return allPosts;
  }

  // --- Data Parsing Logic ---

  List<MemoModelPost> _parseScrapedPostData(Map<String, Object> scrapedData) {
    final List<MemoModelPost> postList = [];

    if (scrapedData.values.isEmpty) {
      _logWarning("No data values found in scraped post data.");
      return postList;
    }

    final dynamic rawItems = scrapedData.values.first;

    // Early exit if it's a known non-post page
    if (rawItems.toString().contains("memo.cash")) {
      // This check might need refinement
      _logInfo("Detected a 'memo.cash' redirect or non-post page. Skipping parsing.");
      return postList;
    }

    if (rawItems is! Iterable) {
      _logWarning("Expected iterable post items, but got ${rawItems.runtimeType}. Data: $rawItems");
      return postList;
    }

    for (final dynamic itemUntyped in rawItems) {
      if (itemUntyped is! Map<String, Object?>) {
        _logWarning("Expected post item to be a Map, but got ${itemUntyped.runtimeType}. Item: $itemUntyped");
        continue;
      }
      final Map<String, Object?> item = itemUntyped;

      // Skip replies based on text content
      if (item["reply"]?.toString().contains("replied") ?? false) {
        continue;
      }

      // --- Robust data extraction with type checks and defaults ---

      final String? topicLink = item["topicLink"]?.toString();
      final String? topicHeader = item["topic"]?.toString();
      final MemoModelTopic? topic = (topicLink != null && topicHeader != null)
          ? MemoModelTopic(url: topicLink, header: topicHeader)
          : null;

      final String? text = item["msg"]?.toString();
      final String? age = item["age"]?.toString();
      final String? tipsRaw = item["tipsInSatoshi"]?.toString();
      final int tipsInSatoshi = int.tryParse(tipsRaw?.replaceAll(",", "") ?? "0") ?? 0;

      final String? created = item["created"]?.toString();

      final String? txHashRaw = item["txhash"]?.toString();
      final String? txHash = (txHashRaw != null && txHashRaw.startsWith(_txHashPrefix))
          ? txHashRaw.substring(_txHashPrefix.length)
          : txHashRaw; // Or handle as error if prefix is mandatory

      final String? imgurUrl = item["imgur"]?.toString();

      final String? creatorName = item["creatorName"]?.toString();
      final String? profileUrlRaw = item["profileUrl"]?.toString();
      MemoModelCreator? creator;
      if (creatorName != null && profileUrlRaw != null && profileUrlRaw.length > _profileUrlPrefixLength) {
        // Assuming the ID is the part after the prefix (e.g., "profile/creatorId")
        final String creatorId = profileUrlRaw.substring(_profileUrlPrefixLength);
        creator = MemoModelCreator(name: creatorName, id: creatorId);
      } else {
        _logWarning("Missing creator name or valid profile URL for post item: $item");
        // Decide how to handle missing creator: skip post, use a default, etc.
        // For now, we allow creator to be null if MemoModelPost supports it.
      }

      // Ensure essential fields are present before creating the post object
      if (text == null || age == null || created == null || txHash == null || creator == null) {
        _logWarning(
          "Skipping post due to missing essential data (text, age, created, txHash, or creator). Item: $item",
        );
        continue;
      }

      MemoModelPost post = MemoModelPost(
        topic: topic,
        text: text,
        age: age,
        tipsInSatoshi: tipsInSatoshi,
        created: created,
        txHash: txHash,
        imgurUrl: imgurUrl,
        creator: creator,
        // likeCounter and replyCounter were commented out, assuming they are not used.
      );

      // Assuming these utility methods are still relevant and safe.
      // If they can throw errors, wrap them in try-catch.
      try {
        MemoScraperUtil.extractUrlsAndHashtags(post);

        // Your existing filter logic:
        // "TODO removing all posts that contain URLs in the text for now, high quality content"
        // This condition seems to filter out posts that DO have URLs.
        // If the goal is to keep ONLY text-only posts OR posts with image URLs (but no text URLs),
        // the logic might need adjustment.
        // Current logic: if (isTextOnly OR (hasImage AND noTextUrls))
        // Your TODO implies you want to REMOVE posts with URLs in text.
        // The original `if (MemoScraperUtil.isTextOnly(post) || post.urls.isNotEmpty)`
        // would `continue` (skip) if it's textOnly OR if it has URLs. This seems to filter out almost everything.
        // Let's assume you want to keep posts that are text-only OR have an imgurUrl but no other URLs in the text.
        bool hasTextUrls = post.urls.any(
          (url) => url != post.imgurUrl,
        ); // Check if any extracted URL is not the imgurUrl

        if (post.imgurUrl == null && hasTextUrls) {
          // If no image, and has text URLs, skip.
          _logInfo("Skipping post (no imgur, has text URLs): ${post.txHash}");
          continue;
        }
        if (post.imgurUrl != null && hasTextUrls && !(post.urls.length == 1 && post.urls.first == post.imgurUrl)) {
          // If has imgur, but also OTHER text URLs, skip.
          _logInfo("Skipping post (has imgur and other text URLs): ${post.txHash}");
          continue;
        }
        // If it reaches here:
        // 1. It's text-only (no imgur, no text URLs).
        // 2. It has an imgurUrl and no OTHER text URLs.
      } catch (e, s) {
        _logError(
          "Error during post-processing (extractUrlsAndHashtags or filtering) for txHash: ${post.txHash}",
          e,
          s,
        );
        continue; // Skip this post on error
      }

      postList.add(post);
    }
    return postList;
  }
}

// --- Assumptions for Models (ensure they support nullability as needed) ---
// class MemoModelPost {
//   final MemoModelTopic? topic;
//   final String text;
//   final String age;
//   final int tipsInSatoshi;
//   final String created;
//   final String txHash;
//   final String? imgurUrl;
//   final MemoModelCreator creator;
//   List<String> urls = []; // Assuming this is populated by extractUrlsAndHashtags

//   MemoModelPost({
//     this.topic,
//     required this.text,
//     required this.age,
//     required this.tipsInSatoshi,
//     required this.created,
//     required this.txHash,
//     this.imgurUrl,
//     required this.creator,
//   });

//   static void addToGlobalPostList(List<MemoModelPost> posts) { /* ... */ }
// }

// class MemoModelTopic {
//   final String url;
//   final String header;
//   MemoModelTopic({required this.url, required this.header});
// }

// class MemoModelCreator {
//   final String name;
//   final String id;
//   MemoModelCreator({required this.name, required this.id});
// }
