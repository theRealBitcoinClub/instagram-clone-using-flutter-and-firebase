import 'dart:async'; // For potential future concurrency, though not strictly needed here yet

import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';

const scraperPageSize = 25;
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

class MemoPostScraper {
  // Renamed for clarity on its purpose
  static const String _rootParserParent = "_root";
  static const String _txHashPrefix = "post/";
  static const int _profileUrlPrefixLength = 8; // Length of "profile/" is 8, adjust if prefix changes

  // --- Configuration Method ---

  ScraperConfig _buildPostsScraperConfig() {
    return ScraperConfig(
      parsers: [
        Parser(id: "posts", parents: [_rootParserParent], type: ParserType.element, selectors: [".post"], multiple: true),
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
    int offsetStep = scraperPageSize,
    bool useRawUrl = false,
    int newPostCount = -1,
    onSkipPost,
  }) async {
    final config = _buildPostsScraperConfig();
    final List<MemoModelPost> allPosts = [];

    _logInfo("Starting post scraping from URL: $baseUrl with initial offset: $initialOffset");

    for (int currentOffset = initialOffset; currentOffset >= 0; currentOffset -= offsetStep) {
      final String scrapeUrl = useRawUrl ? baseUrl : "$baseUrl?offset=$currentOffset&x=$cacheId";
      _logInfo("Scraping posts from: $scrapeUrl");

      try {
        final Map<String, Object> scrapedData = await MemoScraperUtil.createScraper(scrapeUrl, config);
        final List<MemoModelPost> newPosts = await _parseScrapedPostData(
          scrapedData,
          skippedPostWasFiltered: onSkipPost,
          newPostCount: newPostCount,
        );

        if (newPosts.isNotEmpty) {
          // Assuming MemoModelPost.addToGlobalPostList is a desired side effect.
          // Consider if this global modification is the best approach or if
          // this service should just return the data.
          // MemoModelPost.
          // addToGlobalPostList(newPosts);
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

  List<MemoModelPost> _parseScrapedPostData(Map<String, Object> scrapedData, {skippedPostWasFiltered, newPostCount}) {
    final List<MemoModelPost> postList = [];

    if (scrapedData.values.isEmpty) {
      _logWarning("No data values found in scraped post data.");
      return postList;
    }

    final dynamic postDataList = scrapedData.values.first;

    // Early exit if it's a known non-post page
    if (postDataList.toString().contains("memo.cash")) {
      // This check might need refinement
      _logInfo("Detected a 'memo.cash' redirect or non-post page. Skipping parsing.");
      return postList;
    }

    if (postDataList is! Iterable) {
      _logWarning("Expected iterable post items, but got ${postDataList.runtimeType}. Data: $postDataList");
      return postList;
    }

    int index = 0;
    for (final dynamic postData in postDataList) {
      MemoModelPost? post = parsePost(postData);
      if (newPostCount != -1 && index++ >= newPostCount) return postList;

      if (post != null)
        postList.add(post);
      else
        skippedPostWasFiltered();
    }
    return postList;
  }

  Future<MemoModelPost?> fetchAndParsePost(String postId, {bool filterOn = true}) async {
    final String scrapeUrl = "post/$postId";
    _logInfo("Scraping post from: $scrapeUrl");

    var postData = await MemoScraperUtil.createScraperObj(scrapeUrl, _buildPostsScraperConfig(), nocache: true);

    MemoModelPost? post = parsePost(postData.values.first, filterOn: filterOn);
    return post;
  }

  MemoModelPost? parsePost(postData, {bool filterOn = true}) {
    var item = postData;
    if (postData is! Map<String, Object?>) {
      if (postData[0] is Map<String, Object?>)
        item = postData[0];
      else {
        _logWarning("Expected post item to be a Map, but got ${postData.runtimeType}. Item: $postData");
        return null;
      }
    }

    // Skip replies based on text content
    if (item["reply"]?.toString().contains("replied") ?? false) {
      return null;
    }

    // --- Robust data extraction with type checks and defaults ---

    final String? topicLink = item["topicLink"]?.toString();
    final String? topicHeader = item["topic"]?.toString();
    final MemoModelTopic? topic = (topicLink != null && topicHeader != null) ? MemoModelTopic(url: topicLink, id: topicHeader) : null;

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

    if (age == null || created == null || txHash == null || creator == null) {
      _logWarning("Skipping post due to missing essential data (text, age, created, txHash, or creator). Item: $item");
      return null;
    }

    MemoModelPost post = MemoModelPost(
      id: txHash,
      topic: topic,
      text: text,
      // age: age,
      popularityScore: tipsInSatoshi,
      created: created,
      imgurUrl: imgurUrl,
      creator: creator,
      tagIds: [],
      // likeCounter and replyCounter were commented out, assuming they are not used.
    );
    MemoScraperUtil.linkReferencesAndSetId(post, topic, creator);

    if (filterOn && MemoScraperUtil.isTextOnly(post)) {
      return null;
    }

    try {
      bool hasTextUrls = post.urls.any((url) => url != post.imgurUrl); // Check if any extracted URL is not the imgurUrl

      if (filterOn && post.imgurUrl == null && hasTextUrls) {
        // If no image, and has text URLs, skip.
        _logInfo("Skipping post (no imgur, has text URLs): ${post.id}");
        return null;
      }

      //TODO FILTER THIS OR NOT ??
      // if (post.imgurUrl != null && hasTextUrls && !(post.urls.length == 1 && post.urls.first == post.imgurUrl)) {
      //   // If has imgur, but also OTHER text URLs, skip.
      //   _logInfo("Skipping post (has imgur and other text URLs): ${post.uniqueContentId}");
      //   return null;
      // }

      // If it reaches here:
      // 1. It's text-only (no imgur, no text URLs).
      // 2. It has an imgurUrl and no OTHER text URLs.
    } catch (e, s) {
      _logError("Error during post-processing (extractUrlsAndHashtags or filtering) for txHash: ${post.id}", e, s);
      return null; // Skip this post on error
    }
    return post;
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
