import 'package:flutter/foundation.dart';
import 'package:mahakka/config_hide_on_feed_trigger.dart';
import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/firebase/post_scraper_firebase_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:mahakka/memo_data_checker.dart';
import 'package:mahakka/youtube_video_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/topic_service.dart';

class MemoScraperTopic {
  final bool saveToFirebase;
  final SharedPreferences prefs;

  MemoScraperTopic(this.saveToFirebase, this.prefs);

  /// Main entry point for scraping topics and their posts
  Future<void> startScrapeTopics(String cacheId, int startOffset, int endOffset) async {
    final topicService = TopicService();
    final postService = PostScraperFirebaseService();

    for (int offset = startOffset; offset >= endOffset; offset -= 25) {
      // Scrape topics for current offset
      final List<MemoModelTopic> allTopics = await scrapeTopics(offset, cacheId);

      if (allTopics.isEmpty) {
        print("\nSCRAPER TOPICS\nNo topics found for offset $offset");
        continue;
      }

      // Filter topics that have new posts
      final List<MemoModelTopic> topicsWithNewPosts = await _filterTopicsWithNewPosts(allTopics, cacheId);

      if (topicsWithNewPosts.isEmpty) {
        print("\nSCRAPER TOPICS\nNo new posts found for offset $offset");
        continue;
      }

      // Process each topic with new posts
      await _processTopicsWithNewPosts(topicsWithNewPosts, cacheId, topicService, postService);

      print("\nSCRAPER TOPICS\nScraped offset $offset - Found ${topicsWithNewPosts.length} topics with new posts");
    }

    topicService.forceProcessBatch();
    postService.forceProcessBatch();
    print("\nSCRAPER TOPICS\nFINISHED SCRAPING TOPICS: $cacheId");
  }

  /// Scrapes topics from the memo.cash website
  Future<List<MemoModelTopic>> scrapeTopics(int offset, String cacheId, {mockData}) async {
    try {
      var basePath = "topics/all?offset=$offset";
      var path = cacheId.isNotEmpty ? "$basePath&x=$cacheId" : basePath;
      final Map<String, Object> topicsData = await MemoScraperUtil.createScraper(path, _createTopicScraperConfig(), mockData: mockData);

      return _parseTopicsFromData(topicsData);
    } catch (e) {
      print("\nSCRAPER TOPICS\nError scraping topics: $e");
      return [];
    }
  }

  final String keyTopic = "TopicScrape123";

  /// Filters topics to find only those with new posts using lastPostCount
  Future<List<MemoModelTopic>> _filterTopicsWithNewPosts(List<MemoModelTopic> allTopics, String cacheId) async {
    final List<MemoModelTopic> topicsWithNewPosts = [];

    for (final topic in allTopics) {
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
                  if (kDebugMode) print("✅ Batch completed! Processed $processedCount posts");
                  if (failedPostIds != null) {
                    print("❌ Failed posts: ${failedPostIds.join(', ')}");
                  }
                } else {
                  print("❌ Batch failed");
                }
              },
            );
          }
          print("\nSCRAPER TOPICS\nSaved ${newPosts.length} new posts for topic: ${topic.header}");
        }

        // Save the updated post count to SharedPreferences
        final topicKey = "$keyTopic$cacheId${topic.url}";
        await prefs.setString(topicKey, topic.postCount.toString());
      } catch (e) {
        print("\nSCRAPER TOPICS\nError processing topic ${topic.header}: $e");
      }
    }

    // Save topics batch
    topicService.saveTopicsBatch(
      topicsWithNewPosts,
      onFinish: (success, processedCount, failedIds) {
        if (success) {
          if (kDebugMode) print("✅ Batch completed! Processed $processedCount Topics");
          if (failedIds != null) {
            print("❌ Failed topics: ${failedIds.join(', ')}");
          }
        } else {
          print("❌ Batch failed");
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

    try {
      // Scrape all posts for this topic
      final Map<String, Object> postsData = await MemoScraperUtil.createScraper(
        "${topic.url!}?x=$cacheId",
        _createPostScraperConfig(),
        mockData: mockData,
      );

      // Parse all posts
      final List<MemoModelPost> allPosts = await _parsePostsFromData(postsData, topic);

      // Return only the new posts (most recent ones first)
      return allPosts.reversed.take(newPostsCount).toList();
    } catch (e) {
      print("\nSCRAPER TOPICS\nError scraping posts for topic ${topic.header}: $e");
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
      print("\nSCRAPER TOPICS\nError parsing topics data: $e");
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
  Future<List<MemoModelPost>> _parsePostsFromData(Map<String, Object> postsData, MemoModelTopic topic) async {
    final List<MemoModelPost> postList = [];

    try {
      final List postItems = postsData.values.first as List;

      for (final Map<String, Object> postData in postItems) {
        try {
          final MemoModelPost post = _createPostFromData(postData, topic);

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
          print("\nSCRAPER TOPICS\nError parsing individual post: $e");
        }
      }
    } catch (e) {
      print("\nSCRAPER TOPICS\nError parsing posts data: $e");
    }

    return postList;
  }

  /// Creates a MemoModelPost from scraped post data
  MemoModelPost _createPostFromData(Map<String, Object> postData, MemoModelTopic topic) {
    // Parse like count with error handling
    int likeCount = 0;
    try {
      final String likeText = postData["likeCount"].toString();
      likeCount = int.tryParse(likeText.split("\n")[0]) ?? 0;
    } catch (e) {
      print("\nSCRAPER TOPICS\nError parsing like count: $e");
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
    print("\nSCRAPER TOPICS\nTopic: ${currentTopic.header}");
    print("\nSCRAPER TOPICS\nURL: ${currentTopic.url}");
    print("\nSCRAPER TOPICS\nFollowers: ${currentTopic.followerCount}");
    print("\nSCRAPER TOPICS\nPost Count: ${currentTopic.postCount}");
    print("\nSCRAPER TOPICS\nLast Post Count: ${currentTopic.lastPostCount}");
    print("\nSCRAPER TOPICS\nLast Post: ${currentTopic.lastPost}");
  }
}
