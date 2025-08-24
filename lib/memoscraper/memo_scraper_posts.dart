import 'package:instagram_clone1/dart_web_scraper/common/enums.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/parser_model.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_utils.dart';

import '../memomodel/memo_model_creator.dart';
import '../memomodel/memo_model_post.dart';
import '../memomodel/memo_model_topic.dart';

class MemoScraperPost {
  Future<List<MemoModelPost>> startScrapePosts(String url, int startOffset, String cacheId) async {
    final config = createScraperConfigPost();
    final List<MemoModelPost> result = [];

    for (int offset = startOffset; offset >= 0; offset -= 25) {
      MemoModelPost.posts.clear();
      Map<String, Object> posts = await MemoScraperUtil.createScraper("${url}?offset=${offset}&x=${cacheId}", config);

      var postList = createPostList(posts);
      MemoModelPost.addToGlobalPostList(postList);

      result.addAll(postList);
      // MemoScraperUtil.printMemoModelPost(postList);
      print("RUNNING SCRAPE:$url$offset");
    }

    print("FINISH SCRAPE:$url");
    return result;
  }

  ScraperConfig createScraperConfigPost() {
    return ScraperConfig(
      parsers: [
        Parser(id: "posts", parents: ["_root"], type: ParserType.element, selectors: [".post"], multiple: true),
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
        Parser(id: "topic-link", parents: ["posts"], type: ParserType.attribute, selectors: [".topic-link::href"]),
      ],
    );
  }

  List<MemoModelPost> createPostList(Map<String, Object> posts) {
    List<MemoModelPost> postList = [];
    if (posts.values.first.toString().contains("memo.cash")) return [];

    for (Map<String, Object> item in posts.values.first as Iterable) {
      if (item["reply"].toString().contains("replied")) {
        continue;
      }

      // var likeCount = 0;
      // var replyCount = 0;
      // try {
      //   if (item["actions"] != null) {
      //     List<String> actions = item["actions"].toString()
      //         .replaceAll(",", "")
      //         .replaceAll(" ", "")
      //         .split("\n");
      //
      //     // actions.removeWhere((element) => element.isEmpty);
      //     replyCount = int.parse(actions[0]);
      //     likeCount = int.parse(actions[1]);
      //   }
      //   //TODO ACTIONS OR SIMPLY DO NOT HAVE LIKES ONLY TIPS AND MAKE USERS EARN FOR RETWEETS OF POSTS THAT GET TIPS AFTERWARDS BECAUSE OF THEIR RETWEET
      // TODO DO NOT HAVE COMMENTS ON POSTS THAT ARE NOT TOPIC POSTS?
      // } catch (e) {}

      MemoModelPost post = MemoModelPost(
        topic: item["topic-link"] == null
            ? null
            : MemoModelTopic(url: item["topic-link"].toString(), header: item["topic"].toString()),
        text: item["msg"]?.toString(),
        age: item["age"].toString(),
        tipsInSatoshi: int.parse((item["tipsInSatoshi"] ?? "0").toString().replaceAll(",", "")),
        // likeCounter: likeCount,
        // replyCounter: replyCount,
        created: item["created"].toString(),
        txHash: item["txhash"].toString().substring("/post".length),
        imgurUrl: item["imgur"]?.toString(),
        creator: MemoModelCreator(name: item["creatorName"].toString(), id: item["profileUrl"].toString().substring(8)),
      );

      MemoScraperUtil.extractUrlsAndHashtags(post);

      if (MemoScraperUtil.isTextOnly(post) || post.urls.isNotEmpty) {
        continue; //TODO removing all posts that contain URLs in the text for now, high quality content
      }

      postList.add(post);
    }

    return postList;
  }
}
