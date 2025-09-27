import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/firebase/tag_service.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/post_service.dart';
import '../model/memo_model_post.dart';
import 'memo_post_scraper.dart';

const prefskey = "lastTagScrape123";

class MemoScraperTag {
  final Ref ref;
  final bool saveToFirebase;
  final String cacheId;
  MemoScraperTag(this.cacheId, this.ref, this.saveToFirebase);
  final tagService = TagService();
  final postService = PostService();

  /// Main entry point for scraping tags and their posts
  /// [orderBy]: List of sorting methods to scrape (e.g., ['popular', 'new'])
  /// [startOffset]: Starting offset for pagination
  /// [endOffset]: Ending offset for pagination
  /// [cacheId]: Unique identifier for caching purposes
  Future<void> startScrapeTags(List<String> orderBy, int startOffset, int endOffset) async {
    for (String order in orderBy) {
      for (int offset = startOffset; offset >= endOffset; offset -= 25) {
        final prefs = await SharedPreferences.getInstance();
        // check if the first tag has changed
        final sampleTags = await scrapeTags(order, offset);
        if (sampleTags.isEmpty) continue;

        final key = "$prefskey$cacheId";
        final checkString = "${sampleTags[0].lastPost}${sampleTags[0].postCount}";
        final lastCheckString = prefs.getString(key);

        if (lastCheckString == checkString) {
          return; // Stop scraping - no changes detected
        }

        // Scrape tags for current order and offset
        final List<MemoModelTag> allTags = await scrapeTags(order, offset);

        // Filter tags that have new posts
        final List<MemoModelTag> tagsWithNewPosts = await _filterTagsWithNewPosts(allTags);

        if (tagsWithNewPosts.isEmpty) {
          print("\nSCRAPER TAGS\nNo new posts found for $order$offset");
          continue;
        }

        // Process each tag with new posts
        await _processTagsWithNewPosts(tagsWithNewPosts);

        //ITS IMPORTANT TO SET THE CHECKSTRING ONLY AFTER SUCCESSFULLY SCRAPING
        await prefs.setString(key, checkString);
        print("\nSCRAPER TAGS\nScraped $order with offset $offset - Found ${tagsWithNewPosts.length} tags with new posts");
      }
    }

    tagService.forceProcessBatch();
    postService.forceProcessBatch();
    print("\nSCRAPER TAGS\nFINISHED SCRAPING TAGS");
  }

  /// Filters tags to find only those with new posts
  Future<List<MemoModelTag>> _filterTagsWithNewPosts(List<MemoModelTag> allTags) async {
    final prefs = await SharedPreferences.getInstance();

    final List<MemoModelTag> tagsWithNewPosts = [];

    for (final tag in allTags) {
      final tagKey = "$prefskey$cacheId${tag.name}";
      final lastPostCount = int.tryParse(prefs.getString(tagKey) ?? "0") ?? 0;

      if (tag.postCount != null && tag.postCount! > lastPostCount) {
        // This tag has new posts
        tag.lastCount = lastPostCount;
        tagsWithNewPosts.add(tag);
      }
    }

    return tagsWithNewPosts;
  }

  Future<void> persistPostcountAfterSuccessfulScrape(MemoModelTag tag) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString("$prefskey$cacheId${tag.name}", tag.postCount.toString());
  }

  /// Processes tags that have new posts by scraping their content
  Future<void> _processTagsWithNewPosts(List<MemoModelTag> tagsWithNewPosts) async {
    for (final tag in tagsWithNewPosts) {
      try {
        // Scrape new posts for this tag
        final List<MemoModelPost> newPosts = await _scrapeNewPostsForTag(tag, cacheId);

        if (newPosts.isNotEmpty) {
          // Save tag if it's new (no previous posts)
          // if (tag.lastCount == 0) {
          //TODO This be changed as soon as you need the post count data from Firebase, for now only from scrape is relevant
          // await tagService.saveTag(tag);
          // }

          // Save all new posts
          if (kDebugMode && saveToFirebase) {
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
            // postService.savePostsBatch(newPosts);
            //
            // for (final post in newPosts) {
            //   //TODO GET A CHECKSTRING FROM GITHUB THAT INCLUDES 100 MOST RECENTLY SAVED POST IDS AND AVOID DOUBLE PERSIST
            //   await postService.savePost(post);
            // }
          }

          // ref.read(postCacheRepositoryProvider).savePosts(newPosts);
          // ref.read(postCacheRepositoryProvider).clearPagesForFilter(null);

          print("\nSCRAPER TAGS\nSaved ${newPosts.length} new posts for tag: ${tag.name}");
        }
      } catch (e) {
        print("\nSCRAPER TAGS\nError processing tag ${tag.name}: $e");
        // Continue with other tags even if one fails
      }
      persistPostcountAfterSuccessfulScrape(tag);
    }
    tagService.saveTagsBatch(
      tagsWithNewPosts,
      onFinish: (success, processedCount, failedIds) {
        if (success) {
          if (kDebugMode) print("✅ Batch completed! Processed $processedCount TAGS");
          if (failedIds != null) {
            print("❌ Failed TAGS: ${failedIds.join(', ')}");
          }
        } else {
          print("❌ Batch failed");
        }
      },
    );
  }

  /// Scrapes new posts for a specific tag
  Future<List<MemoModelPost>> _scrapeNewPostsForTag(MemoModelTag tag, String cacheId) async {
    final int newPostsCount = tag.postCount! - (tag.lastCount ?? 0);
    int skippedCounter = 0;

    //TODO WHY IS THIS CHECKED TWICE AS IT WAS ALREADY CHECKED WHEN THIS TAG WAS ADDED TO THE LIST THATS BEING PROCESSED
    //TAG.LASTCOUNT IS NOT SET BY ANYONE ELSE BUT THE METHOD THAT PROCESSED THIS BEFORE
    // if (newPostsCount <= 0) {
    //   return [];
    // }

    // Scrape posts for this tag
    final List<MemoModelPost> allPosts = await MemoPostScraper().scrapePostsPaginated(
      useRawUrl: true,
      baseUrl: "t/${tag.name}?p=new",
      initialOffset: 0,
      cacheId: cacheId,
      newPostCount: newPostsCount,
      onSkipPost: () {
        skippedCounter++;
      },
    );

    if (newPostsCount < skippedCounter || newPostsCount - skippedCounter < 0)
      print("\nSCRAPER TAGS\nERROR POSTS FOR TAG: Skipped $skippedCounter posts for tag: ${tag.name} while newPostsCount was $newPostsCount");

    if (newPostsCount - skippedCounter == 0) {
      if (allPosts.length != 0) {
        print("\nSCRAPER TAGS\nSKIPPED EQUALS NEW COUNTER BUT RESULTS ARE NOT EMPTY:");
        return allPosts;
      } else {
        print("\nSCRAPER TAGS\nSKIPPED ALL TAGS: No new VALID posts found for tag: ${tag.name}");
        return [];
      }
    }
    // Return only the new posts (most recent ones first)
    //TODO WHY IS SKIPPED COUNTER ONE IF THERE WAS ONLY ONE NEWPOSTCOUNT BUT THATS CONTAINED IN THE RESULTSET APP POSTS?
    return allPosts.take(newPostsCount - skippedCounter).toList();
  }

  /// Scrapes tags from the memo.cash website
  /// [sortedBy]: Sorting method (e.g., 'popular', 'new')
  /// [offset]: Pagination offset
  Future<List<MemoModelTag>> scrapeTags(String sortedBy, int offset) async {
    try {
      // Build the scrape URL
      final String scrapeUrl = _buildScrapeUrl(sortedBy, offset);

      // Create scraper and get data
      final Map<String, Object> data = await MemoScraperUtil.createScraper(scrapeUrl, _createTagScraperConfig());

      // Parse and return tags

      return _parseTagsFromData(data);
    } catch (e) {
      print("\nSCRAPER TAGS\nError scraping tags: $e");
      return [];
    }
  }

  /// Builds the URL for scraping tags
  String _buildScrapeUrl(String sortedBy, int offset) {
    String url = "tags$sortedBy";
    if (offset != 0) {
      url += "?offset=$offset";
    }
    return url;
  }

  /// Parses tag data from the scraped response
  List<MemoModelTag> _parseTagsFromData(Map<String, Object> data) {
    final List<MemoModelTag> result = [];

    final List<dynamic> tags = data.values.first as List<dynamic>;

    for (final Map<String, Object> tagData in tags) {
      try {
        final List<String> tagStats = tagData["stats"] as List<String>;

        final MemoModelTag tag = MemoModelTag(
          id: tagStats[0], // Tag name
          lastPost: tagStats[1], // Last post timestamp
          postCount: int.tryParse(tagStats[2]) ?? 0, // Post count
        );
        //
        result.add(tag);
      } catch (e) {
        print("\nSCRAPER TAGS\nError parsing tag data: $e");
      }
    }

    return result;
  }

  /// Creates the scraper configuration for parsing tags
  ScraperConfig _createTagScraperConfig() {
    return ScraperConfig(
      parsers: [
        Parser(id: "tags", parents: ["_root"], type: ParserType.element, selectors: ["tr"], multiple: true),
        Parser(id: "stats", parents: ["tags"], type: ParserType.text, selectors: ["td"], multiple: true),
      ],
    );
  }
}
