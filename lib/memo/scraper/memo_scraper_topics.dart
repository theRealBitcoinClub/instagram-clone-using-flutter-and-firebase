import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/config_hide_on_feed_trigger.dart';
import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/api/memo_model_post_api.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/firebase/post_scraper_firebase_service.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:mahakka/memo_data_checker.dart';
import 'package:mahakka/youtube_video_checker.dart';

import '../firebase/topic_service.dart';
import '../isar/isar_shared_preferences.dart';

class MemoScraperTopic {
  final bool saveToFirebase;
  final IsarSharedPreferences prefs;

  MemoScraperTopic(this.saveToFirebase, this.prefs);

  /// Main entry point for scraping topics and their posts
  Future<void> startScrapeTopics(String cacheId, int startOffset, int endOffset) async {
    final topicService = TopicService();
    final postService = PostScraperFirebaseService();

    for (int offset = startOffset; offset >= endOffset; offset -= 25) {
      // Scrape topics for current offset
      final List<MemoModelTopic> allTopics = await scrapeTopics(offset, cacheId);

      if (allTopics.isEmpty) {
        _print("\nSCRAPER TOPICS\nNo topics found for offset $offset");
        continue;
      }

      // Filter topics that have new posts
      final List<MemoModelTopic> topicsWithNewPosts = await _filterTopicsWithNewPosts(allTopics, cacheId);

      if (topicsWithNewPosts.isEmpty) {
        _print("\nSCRAPER TOPICS\nNo new posts found for offset $offset");
        continue;
      }

      // Process each topic with new posts
      await _processTopicsWithNewPosts(topicsWithNewPosts, cacheId, topicService, postService);

      _print("\nSCRAPER TOPICS\nScraped offset $offset - Found ${topicsWithNewPosts.length} topics with new posts");
    }

    topicService.forceProcessBatch();
    postService.forceProcessBatch();
    _print("\nSCRAPER TOPICS\nFINISHED SCRAPING TOPICS: $cacheId");
  }

  /// Scrapes topics from the memo.cash website
  Future<List<MemoModelTopic>> scrapeTopics(int offset, String cacheId, {mockData}) async {
    try {
      var basePath = "topics/all?offset=$offset";
      var path = cacheId.isNotEmpty ? "$basePath&x=$cacheId" : basePath;
      final Map<String, Object> topicsData = await MemoScraperUtil.createScraper(path, _createTopicScraperConfig(), mockData: mockData);

      return _parseTopicsFromData(topicsData);
    } catch (e) {
      _print("\nSCRAPER TOPICS\nError scraping topics: $e");
      return [];
    }
  }

  final String keyTopic = "TopicScrape123";

  /// Filters topics to find only those with new posts using lastPostCount
  Future<List<MemoModelTopic>> _filterTopicsWithNewPosts(List<MemoModelTopic> allTopics, String cacheId) async {
    final List<MemoModelTopic> topicsWithNewPosts = [];

    for (final topic in allTopics) {
      //filter topics that dont match the regexp
      topic.id = topic.id.startsWith("@") ? topic.id.substring(1) : topic.id;
      if ("@${topic.id}" != MemoRegExp.extractTopics("@${topic.id}").firstOrNull) {
        continue;
      }

      if (topic.id.length > MemoVerifier.maxTopicLength) {
        continue;
      }

      final topicKey = "$keyTopic$cacheId${topic.url}";
      final lastPostCount = int.tryParse(prefs.getString(topicKey) ?? "0") ?? 0;

      // Store the previous post count for later comparison
      topic.lastPostCount = lastPostCount;

      if (topic.postCount != null && topic.postCount! > lastPostCount) {
        // This topic has new posts
        topicsWithNewPosts.add(topic);
      }
    }

    return topicsWithNewPosts;
  }

  /// Processes topics that have new posts by scraping their content
  Future<void> _processTopicsWithNewPosts(
    List<MemoModelTopic> topicsWithNewPosts,
    String cacheId,
    TopicService topicService,
    PostScraperFirebaseService postService,
  ) async {
    for (final topic in topicsWithNewPosts) {
      try {
        final List<MemoModelPost> newPosts = await scrapeTopicHarvestPosts(topic, cacheId);
        if (newPosts.isNotEmpty) {
          if (saveToFirebase) {
            postService.savePostsBatch(
              newPosts,
              onFinish: (success, processedCount, failedPostIds) {
                if (success) {
                  if (kDebugMode) _print("✅ Batch completed! Processed $processedCount posts");
                  if (failedPostIds != null) {
                    _print("❌ Failed posts: ${failedPostIds.join(', ')}");
                  }
                } else {
                  _print("❌ Batch failed");
                }
              },
            );
          }
          _print("\nSCRAPER TOPICS\nSaved ${newPosts.length} new posts for topic: ${topic.header}");
        }

        // Save the updated post count to SharedPreferences
        final topicKey = "$keyTopic$cacheId${topic.url}";
        await prefs.setString(topicKey, topic.postCount.toString());
      } catch (e) {
        _print("\nSCRAPER TOPICS\nError processing topic ${topic.header}: $e");
      }
    }

    // Save topics batch
    topicService.saveTopicsBatch(
      topicsWithNewPosts,
      onFinish: (success, processedCount, failedIds) {
        if (success) {
          if (kDebugMode) _print("✅ Batch completed! Processed $processedCount Topics");
          if (failedIds != null) {
            _print("❌ Failed topics: ${failedIds.join(', ')}");
          }
        } else {
          _print("❌ Batch failed");
        }
      },
    );
  }

  /// Scrapes posts for a specific topic, only fetching new posts
  Future<List<MemoModelPost>> scrapeTopicHarvestPosts(MemoModelTopic topic, String cacheId, {mockData}) async {
    final int newPostsCount = topic.postCount! - (topic.lastPostCount ?? 0);

    if (newPostsCount <= 0) {
      return [];
    }

    var scrapeUrl = "${topic.url!}?x=$cacheId";
    String apiUrl = "https://beta-api.memo.cash/post/topic?topic=${topic.url!.split("/").last}";
    Iterable<dynamic>? fetchedFromApiList;
    Map<String, Object>? postsData;

    try {
      var response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        fetchedFromApiList = json.decode(response.body);
      } else {
        _print("Api request response.statusCode != 200 $apiUrl, ${response.statusCode}, fallback to scraper");
      }
    } catch (e) {
      _print("Api request url: $apiUrl failed, fallback to scraper, error: $e");
    }

    try {
      if (fetchedFromApiList == null) {
        postsData = await MemoScraperUtil.createScraper(scrapeUrl, _createPostScraperConfig(), mockData: mockData);
      }
    } catch (e) {
      _print("Scraping failed for url: $scrapeUrl error: $e");
    }
    _print("success on api: ${fetchedFromApiList != null}, url: $apiUrl, success on scrape: ${postsData != null}, url: $scrapeUrl");

    try {
      // Parse all posts
      final List<MemoModelPost> allPosts = await _parsePostsFromData(topic, postsData: postsData, postListFromApiFetch: fetchedFromApiList);

      return allPosts.take(newPostsCount).toList();
    } catch (e) {
      _print("\nSCRAPER TOPICS\nError scraping posts for topic ${topic.header}: $e");
      return [];
    }
  }

  /// Creates the scraper configuration for parsing topics
  ScraperConfig _createTopicScraperConfig() {
    return ScraperConfig(
      parsers: [
        Parser(id: "topics", parents: ["_root"], type: ParserType.element, selectors: ["td"], multiple: true),
        Parser(id: "topic", parents: ["topics"], type: ParserType.text, selectors: ["a"]),
        Parser(id: "topicURL", parents: ["topics"], type: ParserType.url, selectors: ["a"]),
        Parser(id: "tbody", parents: ["_root"], type: ParserType.text, selectors: ["tbody"]),
      ],
    );
  }

  /// Parses topic data from the scraped response
  List<MemoModelTopic> _parseTopicsFromData(Map<String, Object> topicsData) {
    final List<MemoModelTopic> topicList = [];

    try {
      final String tbodyContent = topicsData["tbody"].toString();
      final List<String> cleanBody = _cleanTbodyContent(tbodyContent);

      final List topicItems = topicsData.values.first as List;

      int itemIndex = 0;
      for (final Map<String, Object> topicData in topicItems) {
        if (itemIndex + 3 >= cleanBody.length) {
          break; // Prevent index out of bounds
        }

        final MemoModelTopic topic = MemoModelTopic(
          id: topicData["topic"].toString(),
          url: topicData["topicURL"].toString(),
          followerCount: int.tryParse(cleanBody[itemIndex + 3]) ?? 0,
          lastPost: cleanBody[itemIndex + 1],
          postCount: int.tryParse(cleanBody[itemIndex + 2]) ?? 0,
        );

        topicList.add(topic);
        itemIndex += 4;
      }
    } catch (e) {
      _print("\nSCRAPER TOPICS\nError parsing topics data: $e");
    }

    return topicList;
  }

  /// Cleans and processes the tbody content
  List<String> _cleanTbodyContent(String tbodyContent) {
    return tbodyContent.replaceAll(",", "").split("\n").where((line) => line.trim().isNotEmpty).map((line) => line.trim()).toList();
  }

  /// Creates the scraper configuration for parsing posts
  ScraperConfig _createPostScraperConfig() {
    return ScraperConfig(
      parsers: [
        Parser(id: "posts", parents: ["_root"], type: ParserType.element, selectors: [".topic-post"], multiple: true),
        Parser(id: "msg", parents: ["posts"], type: ParserType.text, selectors: [".message"]),
        Parser(id: "profileUrl", parents: ["posts"], type: ParserType.url, selectors: [".profile"]),
        Parser(id: "age", parents: ["posts"], type: ParserType.text, selectors: [".time"]),
        Parser(id: "likeCount", parents: ["posts"], type: ParserType.text, selectors: [".like-info"]),
        Parser(id: "replyCount", parents: ["posts"], type: ParserType.text, selectors: [".reply-count"]),
        Parser(id: "tipsInSatoshi", parents: ["posts"], type: ParserType.text, selectors: [".tip-button"]),
        Parser(id: "created", parents: ["posts"], type: ParserType.attribute, selectors: [".time::title"]),
        Parser(id: "txhash", parents: ["posts"], type: ParserType.url, selectors: [".time"]),
        Parser(id: "creatorName", parents: ["posts"], type: ParserType.text, selectors: [".profile"]),
        Parser(id: "imgur", parents: ["posts"], type: ParserType.attribute, selectors: [".imgur::href"]),
      ],
    );
  }

  /// Parses posts from the scraped response
  Future<List<MemoModelPost>> _parsePostsFromData(
    MemoModelTopic topic, {
    Map<String, Object>? postsData,
    Iterable? postListFromApiFetch,
  }) async {
    final List<MemoModelPost> postList = [];

    try {
      var isScraperFetch = postListFromApiFetch == null;
      final List postItems = isScraperFetch ? postsData!.values.first as List : postListFromApiFetch.toList();

      for (final Map<String, dynamic> postMap in postItems) {
        try {
          final MemoModelPost post = isScraperFetch
              ? _createPostFromData(postMap, topic)
              : MemoModelPostAPI.fromJson(postMap).toMemoModelPost();

          post.text ??= "";
          if (MemoScraperUtil.isTextOnly(post)) {
            continue; // Skip text-only posts
          }

          if (post.youtubeId != null && !(await YouTubeVideoChecker().isVideoAvailable(post.youtubeId!))) continue;
          if (post.imgurUrl != null && !(await MemoDataChecker().isImageValid(url: post.imgurUrl!))) continue;

          if (post.text != null &&
              hideOnFeedTrigger.any((word) => post.text!.toLowerCase().contains(word.toLowerCase())) &&
              !post.hasImageMedia) {
            continue;
          }

          postList.add(post);
        } catch (e) {
          _print("\nSCRAPER TOPICS\nError parsing individual post: $e");
        }
      }
    } catch (e) {
      _print("\nSCRAPER TOPICS\nError parsing posts data: $e");
    }

    return postList;
  }

  /// Creates a MemoModelPost from scraped post data
  MemoModelPost _createPostFromData(Map<String, dynamic> postData, MemoModelTopic topic) {
    // Parse like count with error handling
    int likeCount = 0;
    try {
      final String likeText = postData["likeCount"].toString();
      likeCount = int.tryParse(likeText.split("\n")[0]) ?? 0;
    } catch (e) {
      _print("\nSCRAPER TOPICS\nError parsing like count: $e");
    }

    // Create creator object
    final String profileUrl = postData["profileUrl"].toString();
    final MemoModelCreator creator = MemoModelCreator(
      name: postData["creatorName"].toString(),
      id: profileUrl.substring(8), // Remove "/profile/" prefix
    );

    // Parse transaction hash
    final String txHashUrl = postData["txhash"].toString();
    final String id = txHashUrl.substring("post/".length);

    // Create post object
    final MemoModelPost post = MemoModelPost(
      id: id,
      topicId: topic.id,
      text: postData["msg"]?.toString(),
      popularityScore: int.tryParse((postData["tipsInSatoshi"] ?? "0").toString().replaceAll(",", "")) ?? 0,
      likeCounter: likeCount,
      replyCounter: int.tryParse((postData["replyCount"] ?? "0").toString()) ?? 0,
      created: postData["created"].toString(),
      imgurUrl: postData["imgur"]?.toString(),
      creator: creator,
      tagIds: [],
    );

    // Set up references and IDs
    MemoScraperUtil.linkReferencesAndSetId(post, topicId: topic.id, creatorId: creator.id);

    return post;
  }

  /// Debug method to print topic information
  void printCurrentMemoModelTopic(MemoModelTopic currentTopic) {
    _print("\nSCRAPER TOPICS\nTopic: ${currentTopic.header}");
    _print("\nSCRAPER TOPICS\nURL: ${currentTopic.url}");
    _print("\nSCRAPER TOPICS\nFollowers: ${currentTopic.followerCount}");
    _print("\nSCRAPER TOPICS\nPost Count: ${currentTopic.postCount}");
    _print("\nSCRAPER TOPICS\nLast Post Count: ${currentTopic.lastPostCount}");
    _print("\nSCRAPER TOPICS\nLast Post: ${currentTopic.lastPost}");
  }

  void _print(String s) {
    if (kDebugMode) print("TOPSCRAPE: $s");
  }
}
