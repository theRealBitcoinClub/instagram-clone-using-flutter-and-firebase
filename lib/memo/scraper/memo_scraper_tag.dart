import 'package:mahakka/dart_web_scraper/common/enums.dart';
import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/memo/firebase/tag_service.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/memo/scraper/memo_post_service.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/post_service.dart';
import '../model/memo_model_post.dart';

class MemoScraperTag {
  Future<void> startScrapeTags(List<String> orderBy, int startOffset, int endOffset, String cacheId) async {
    for (String order in orderBy) {
      for (int off = startOffset; off >= endOffset; off -= 25) {
        var posts = [];
        List<MemoModelTag> allTags = await scrapeTags(order, off);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        var checkString = allTags[0].lastPost.toString() + allTags[0].postCount.toString();
        var key = "lastTagScrape" + cacheId;
        if (prefs.getString(key) == checkString) {
          print("STOP SCRAPE TAGS: $checkString");
          return;
        }

        List<MemoModelTag> tagsToPersist = [];

        for (MemoModelTag t in allTags) {
          String check = t.postCount.toString();
          var keyPerTag = key + t.name;
          if (prefs.getString(keyPerTag) == check) {
            continue; //NO NEW POST ON THIS TOPIC
          }
          prefs.setString(keyPerTag, check);
          tagsToPersist.add(t);
        }

        for (MemoModelTag tag in tagsToPersist) {
          posts.addAll(await MemoPostService().scrapePostsPaginated(baseUrl: "t/${tag.name}", initialOffset: 0, cacheId: cacheId));
          //TODO this already happens inside scrapepostspaginated
          // MemoModelPost.addToGlobalPostList(list);
        }
        // MemoModelTag.tagsToPersist.addAll(tagsToPersist);
        var tagService = TagService();
        var postService = PostService();
        for (MemoModelTag t in tagsToPersist) {
          tagService.saveTag(t);
          // indexTopics++;
          for (MemoModelPost p in posts) {
            postService.savePost(p);
            // indexPosts++;
          }
          posts.clear();
        }
        tagsToPersist.clear();
        print("$off RUNNING SCRAPE:$order$off");
      }
    }
    print("FINISH SCRAPE TAGS");
  }

  Future<List<MemoModelTag>> scrapeTags(String sortedBy, offset) async {
    String scrapeUrl = "tags${sortedBy}";
    scrapeUrl += offset != 0 ? "?offset=${offset}" : "";

    Map<String, Object> data = await MemoScraperUtil.createScraper(scrapeUrl, createConfigPost());
    List<MemoModelTag> result = [];

    List<dynamic> tags = data.values.first as List<dynamic>;
    for (Map<String, Object> tag in tags) {
      List<String> tagRow = tag["stats"] as List<String>;
      MemoModelTag t = MemoModelTag(id: tagRow[0].toString(), lastPost: tagRow[1], postCount: int.parse(tagRow[2]));
      result.add(t);
    }
    // print("object");
    return result;
  }

  ScraperConfig createConfigPost() {
    return ScraperConfig(
      parsers: [
        Parser(id: "tags", parents: ["_root"], type: ParserType.element, selectors: ["tr"], multiple: true),
        Parser(multiple: true, id: "stats", parents: ["tags"], type: ParserType.text, selectors: ["td"]),
      ],
    );
  }
}
