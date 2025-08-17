import 'package:instagram_clone1/dart_web_scraper/common/enums.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/parser_model.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_posts.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_utils.dart';

import '../memomodel/memo_model_creator.dart';
import '../memomodel/memo_model_tag.dart';

class MemoScraperTag {
  void startScrapeTags(List<String> orderBy, int offset) async {
    for (String order in orderBy) {
      for (int off = offset; off >= 0; off -= 25) {
        List<MemoModelTag> tags = await scrapeTags(order, off);
        for (MemoModelTag tag in tags) {
          tag.posts.addAll(await MemoScraperPost().startScrapePosts("t/${tag.name}", off));
        }
        // print("object");
      }
    }
  }

  Future<List<MemoModelTag>> scrapeTags(String sortedBy, offset) async {
    String scrapeUrl = "tags${sortedBy}";
    scrapeUrl += offset != 0 ? "?offset=${offset}" : "";

    Map<String, Object> data = await MemoScraperUtil.createScraper(scrapeUrl, createConfigPost());
    List<MemoModelTag> result = [];

    List<dynamic> tags = data.values.first as List<dynamic>;
    for (Map<String, Object> tag in tags) {
      List<String> tagRow = tag["stats"] as List<String>;
      MemoModelTag t = MemoModelTag(
          name: tagRow[0].toString(),
          lastPost: tagRow[1],
          postCount: int.parse(tagRow[2]),
      );
      result.add(t);
    }
    // print("object");
    return result;
  }

  ScraperConfig createConfigPost() {
    return ScraperConfig(
      parsers: [
        Parser(
            id: "tags",
            parents: ["_root"],
            type: ParserType.element,
            selectors: [
              "tr",
            ],
            multiple: true
        ),
        Parser(
            multiple: true,
            id: "stats",
            parents: ["tags"],
            type: ParserType.text,
            selectors: [
              "td",
            ]
        )
      ],
    );
  }
}