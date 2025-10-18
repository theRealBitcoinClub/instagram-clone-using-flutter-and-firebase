import 'dart:async'; // For potential future concurrency, though not strictly needed here yet
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../config_hide_on_feed_trigger.dart';
import '../../memo_data_checker.dart';
import '../../youtube_video_checker.dart';
import '../api/memo_model_post_api.dart';
import '../memo_reg_exp.dart';

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
      final String apiUrl =
          "https://beta-api.memo.cash/post/tag?tag=${baseUrl.split("/").last.split("?").first}&offset=$currentOffset&x=$cacheId";
      _logInfo("Scraping posts scrapeUrl: $scrapeUrl");
      _logInfo("Scraping posts apiUrl: $apiUrl");

      Iterable<dynamic>? fetchedFromApiList;
      Map<String, Object>? scrapedData;

      try {
        var response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          fetchedFromApiList = json.decode(response.body);
        } else {
          _logWarning("Api request response.statusCode != 200 $apiUrl, ${response.statusCode}, fallback to scraper");
        }
      } catch (e) {
        _logError("Api request $apiUrl failed, fallback to scraper", e: e);
      }

      try {
        if (fetchedFromApiList == null) scrapedData = await MemoScraperUtil.createScraper(scrapeUrl, config);
      } catch (e) {
        _logError("Scraping failed for $scrapeUrl", e: e);
      }
      _logInfo("success on api: ${fetchedFromApiList != null}, success on scrape: ${scrapedData != null}");

      try {
        final List<MemoModelPost> newPosts = await _parseScrapedPostData(
          scrapedData: scrapedData,
          skippedPostWasFiltered: onSkipPost,
          newPostCount: newPostCount,
          postListFromApiFetch: fetchedFromApiList,
        );

        if (newPosts.isNotEmpty) {
          allPosts.addAll(newPosts);
          _logInfo("Successfully scraped and processed ${newPosts.length} posts from offset $currentOffset.");
        } else {
          _logInfo("No new posts found at offset $currentOffset.");
        }
      } catch (e, s) {
        _logError("Failed to scrape posts from $scrapeUrl", e: e);
      }
    }

    _logInfo("Finished scraping posts from base URL: $baseUrl. Total posts fetched: ${allPosts.length}");
    return allPosts;
  }

  // --- Data Parsing Logic ---

  Future<List<MemoModelPost>> _parseScrapedPostData({
    Map<String, Object>? scrapedData,
    skippedPostWasFiltered,
    newPostCount,
    Iterable? postListFromApiFetch,
  }) async {
    final List<MemoModelPost> postList = [];

    if (scrapedData != null && scrapedData.values.isEmpty) {
      _logWarning("No data values found in scraped post data.");
      return postList;
    }

    if (scrapedData == null && postListFromApiFetch == null) {
      _logError("No API data nor scrape data)");
      return postList;
    }

    final dynamic postDataList = postListFromApiFetch ?? scrapedData!.values.first;

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
      MemoModelPost? post = await parsePost(postData, isFromApiFetch: postListFromApiFetch != null);
      if (newPostCount != -1 && index++ >= newPostCount) return postList;

      if (post != null) {
        postList.add(post);
      } else {
        skippedPostWasFiltered();
      }
    }
    return postList;
  }

  Future<MemoModelPost?> fetchAndParsePost(String postId, {bool filterOn = true}) async {
    // First try: Fetch from the new API
    try {
      _logInfo("Attempting to fetch post from API for txHash: $postId");
      final MemoModelPost? apiPost = await _fetchPostFromAPI(postId);

      if (apiPost != null) {
        _logInfo("Successfully fetched post from API: $postId");
        return apiPost;
      } else {
        _logInfo("API returned null for post: $postId, falling back to scraping");
      }
    } catch (e) {
      _logError("API fetch failed for post $postId: $e");
      _logInfo("Falling back to scraping for post: $postId");
    }

    // Fallback: Use the existing scraping strategy
    try {
      final String scrapeUrl = "post/$postId";
      _logInfo("Scraping post from: $scrapeUrl");

      var postData = await MemoScraperUtil.createScraperObj(scrapeUrl, _buildPostsScraperConfig(), nocache: true);

      MemoModelPost? post = await parsePost(postData.values.first, strictFilter: filterOn);

      if (post != null) {
        _logInfo("Successfully scraped post: $postId");
      } else {
        _logError("Scraping also failed to return a post for: $postId");
      }

      return post;
    } catch (e) {
      _logError("Scraping also failed for post $postId: $e");
      return null;
    }
  }

  Future<MemoModelPost?> _fetchPostFromAPI(String txHash) async {
    try {
      final String apiUrl = "https://beta-api.memo.cash/post/details?txHash=$txHash";
      _logInfo("Making API request to: $apiUrl");

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Check if the API returned success and has data
        if (responseData['tx_hash'] == txHash) {
          final apiPost = MemoModelPostAPI.fromJson(responseData);
          return apiPost.toMemoModelPost();
        } else {
          _logError("API returned unsuccessful response for $txHash: ${responseData['error'] ?? 'Unknown error'}");
          return null;
        }
      } else {
        _logError("API request failed with status code: ${response.statusCode} for $txHash");
        return null;
      }
    } catch (e) {
      _logError("Exception in _fetchPostFromAPI for $txHash: $e");
      rethrow; // Re-throw to be caught by the outer try-catch
    }
  }

  void _logInfo(String message) {
    print("MemoPostScraper INFO: $message");
    Sentry.logger.info("MemoPostScraper: $message");
  }

  void _logError(String message, {e}) {
    Sentry.logger.error("MemoPostScraper ERROR: $message error: $e");
  }

  // Future<MemoModelPost?> fetchAndParsePost(String postId, {bool filterOn = true}) async {
  //   final String scrapeUrl = "post/$postId";
  //   _logInfo("Scraping post from: $scrapeUrl");
  //
  //   var postData = await MemoScraperUtil.createScraperObj(scrapeUrl, _buildPostsScraperConfig(), nocache: true);
  //
  //   MemoModelPost? post = await parsePost(postData.values.first, filterOn: filterOn);
  //   return post;
  // }

  Future<MemoModelPost?> parsePost(postData, {bool strictFilter = true, bool isFromApiFetch = false}) async {
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
    MemoModelPost post;
    if (isFromApiFetch) {
      post = MemoModelPostAPI.fromJson(item).toMemoModelPost();
    } else {
      post = parsePostFromScraperObject(item);
    }

    if (!(await hitsTheFilter(post, strictFilter)))
      return post;
    else
      return null;
  }

  Future<bool> hitsTheFilter(MemoModelPost post, bool strictFilter) async {
    if (strictFilter && MemoScraperUtil.isTextOnly(post)) {
      return true;
    }

    if (post.youtubeId != null && !(await YouTubeVideoChecker().isVideoAvailable(post.youtubeId!))) return true;
    if (post.imgurUrl != null && !(await MemoDataChecker().isImageValid(url: post.imgurUrl!))) return true;

    //TODO MAKE SURE THAT TWITTER IMAGE POSTS ARE NOT DISMISSED BUT SHALL ONLY HAVE EMPTY MEDIA ID SO THAT THE USER CAN STILL HIT THE LINK IN DESCRIPTION

    //TODO replace the trigger URLS, replace all the URLs except one that is used for preview

    if (post.text != null && hideOnFeedTrigger.any((word) => post.text!.toLowerCase().contains(word.toLowerCase())) && !post.hasImageMedia) {
      return true;
    }

    try {
      // Alternatively, check if all URLs are whitelisted
      //TODO boost this post on feed
      bool hasOnlyWhitelistedUrls = MemoRegExp.hasOnlyWhitelistedUrls(post.urls);

      bool hasAtleastWhitelistedDomain = MemoRegExp(post.text!).hasAnyWhitelistedMediaUrl();
      // if (!hasAtleastWhitelistedDomain) {
      //   post.text = TextFilter.replaceNonWhitelistedDomains(post.text!);
      // }

      //TODO specific posts only appear on own profile if user has sufficient token

      // Or if you want to be more specific about what constitutes "text URLs"
      if (strictFilter &&
          post.imgurUrl == null &&
          post.youtubeId == null &&
          post.imageUrl == null &&
          post.ipfsCid == null &&
          post.videoUrl == null &&
          !hasAtleastWhitelistedDomain) {
        // If no image, and has URLs that aren't from approved media domains, skip.
        _logInfo(
          "Skipping post (only text, no imgur (let imgur & youtube pass always), has zero whitelisted domains): ${post.urls.toString()}",
        );
        return true;
      }
    } catch (e, s) {
      _logError("Error during post-processing (extractUrlsAndHashtags or filtering) for txHash: ${post.id}", e: e);
      return true; // Skip this post on error
    }
    return false;
  }

  MemoModelPost parsePostFromScraperObject(item) {
    final String? topicLink = item["topicLink"]?.toString();
    final String? topicHeader = item["topic"]?.toString();
    //TODO MAKE THIS COMPATIBLE WITH THE NEW @TOPIC
    // final MemoModelTopic? topic = (topicLink != null && topicHeader != null) ? MemoModelTopic(url: topicLink, id: topicHeader) : null;

    final String? text = item["msg"]?.toString();
    // final String? age = item["age"]?.toString();
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
    String creatorID = "";
    if (creatorName != null && profileUrlRaw != null && profileUrlRaw.length > _profileUrlPrefixLength) {
      // Assuming the ID is the part after the prefix (e.g., "profile/creatorId")
      creatorID = profileUrlRaw.substring(_profileUrlPrefixLength);
      creator = MemoModelCreator(name: creatorName, id: creatorID);
    } else {
      _logWarning("Missing creator name or valid profile URL for post item: $item");
      // Decide how to handle missing creator: skip post, use a default, etc.
      // For now, we allow creator to be null if MemoModelPost supports it.
    }

    // Ensure essential fields are present before creating the post object

    //TODO the created is generated if missing, age is derived from that, txhash will always be present and creator anyway
    // if (age == null || created == null || txHash == null || creator == null) {
    //   _logWarning("Skipping post due to missing essential data (text, age, created, txHash, or creator). Item: $item");
    //   return null;
    // }

    MemoModelPost post = MemoModelPost(
      id: txHash,
      topicId: topicHeader ?? "",
      text: text,
      // age: age,
      popularityScore: tipsInSatoshi,
      created: created,
      imgurUrl: imgurUrl,
      creator: creator,
      creatorId: creatorID,
      tagIds: [],
      // likeCounter and replyCounter were commented out, assuming they are not used.
    );
    MemoScraperUtil.linkReferencesAndSetId(post, topicId: topicHeader, creatorId: creator!.id);
    return post;
  }
}
