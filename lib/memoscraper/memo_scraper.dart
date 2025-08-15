import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/dart_web_scraper/common/enums.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/parser_model.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:instagram_clone1/dart_web_scraper/dart_web_scraper/web_scraper.dart';
import 'package:html/dom.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memomodel/memo_model_creator.dart';
import '../memomodel/memo_model_post.dart';
import '../memomodel/memo_model_topic.dart';

class MemoScraper {
  String baseUrl = "https://memo.cash/";
  WebScraper webScraper = WebScraper();


  void startScrapeCreators(List<String> orderBy) async {
    for (String order in orderBy) {
      List<MemoModelCreator> creators = await MemoScraper().scrapeCreators(order);
      for (MemoModelCreator creator in creators) {
        await MemoScraper().loadCreator(creator.id!, creator);
      }
    }
  }

  Future<MemoModelCreator> loadCreator(String id, MemoModelCreator? creator) async {
    Map<String, Object> data = await createScraper("profile/${id}", createScraperConfigProfile());

    var split = data.values.first.toString().replaceAll(" ", "").split("\n");
    split.removeWhere((element) => element.isEmpty);

    MemoModelCreator result = creator == null ? MemoModelCreator() : creator;

    result.name = split[0];
    result.profileText = split[1];

    return result;
  }

  ScraperConfig createScraperConfigProfile() {
    return ScraperConfig(
      parsers: [
        Parser(
            id: "nameAndText",
            parents: ["_root"],
            type: ParserType.text,
            selectors: [
              ".title",
            ]
        )
      ],
    );
  }

  Future<List<MemoModelCreator>> scrapeCreators(String sortedBy) async {
    Map<String, Object> users = await createScraper("profiles${sortedBy}", createScraperConfigCreators());
    List<MemoModelCreator> creators = [];

    List<dynamic> items = users.values.first as List<dynamic>;
    for (Map<String, Object> item in items) {
      List<String> stats = item["stats"] as List<String>;
      MemoModelCreator creator = MemoModelCreator(
          id: item["id"].toString().substring("profile".length + 1),
          followerCount: int.parse(stats[2].replaceAll(",", '')),
          actions: int.parse(stats[1].replaceAll(",", '')),
          created: stats[3],
          lastActionDate: stats[4]
      );
      creators.add(creator);
    }
    // print("object");
    return creators;
  }


  ScraperConfig createScraperConfigCreators() {
    return ScraperConfig(
      parsers: [
        Parser(
            id: "users",
            parents: ["_root"],
            type: ParserType.element,
            selectors: [
              "tr",
            ],
            multiple: true
        ),
        Parser(
            id: "id",
            parents: ["users"],
            type: ParserType.attribute,
            selectors: [
              "a::href",
            ]
        ),
        Parser(
            multiple: true,
            id: "stats",
            parents: ["users"],
            type: ParserType.text,
            selectors: [
              "td",
            ]
        )
      ],
    );
  }

  void startScrapeTopics() async {
    Map<String, Object> topics = await createScraper("topics/all", createScraperConfigMemoModelTopic());

    List<MemoModelTopic> topicList = createMemoModelTopicList(topics);

    final config = createScraperConfigMemoModelPost();

    // int index = 0;

    for (MemoModelTopic currentTopic in topicList) {
      // if (index++ > 2) {
      //   continue;
      // }

      // printCurrentMemoModelTopic(currentTopic);

      Future<Map<String, Object>> posts = createScraper(currentTopic.url!, config);

      posts.then((value) {
        var postList = createMemoModelPostList(value, currentTopic);
        MemoModelPost.addToGlobalPostList(postList);

        // printMemoModelPost(postList);
      },);
    }
  }

  Future<Map<String, Object>> createScraper(String path, ScraperConfig cfg) async {
    String? cachedData = await loadCachedData(path);
    Map<String, Object> topics = await webScraper.scrape(
      html: cachedData == null ? null : Document.html(cachedData),
      concurrentParsing: true,
      url: Uri.parse(baseUrl + path),
      scraperConfig: cfg,
      onCacheHtmlString: (data) => cacheData(path, data),
    );
    return topics;
  }

  ScraperConfig createScraperConfigMemoModelTopic() {
    return ScraperConfig(
      parsers: [
        Parser(
            id: "topics",
            parents: ["_root"],
            type: ParserType.element,
            selectors: [
              "td",
            ],
            multiple: true
        ),
        Parser(
            id: "topic",
            parents: ["topics"],
            type: ParserType.text,
            selectors: [
              "a",
            ]
        ),
        Parser(
            id: "topicURL",
            parents: ["topics"],
            type: ParserType.url,
            selectors: [
              "a",
            ]
        ),
        Parser(
            id: "tbody",
            parents: ["_root"],
            type: ParserType.text,
            selectors: [
              "tbody",
            ]
        )
      ],
    );
  }

  List<MemoModelTopic> createMemoModelTopicList(Map<String, Object> topics) {
    List<MemoModelTopic> topicList = [];

    var tbody = topics.values.elementAt(1).toString()
        .replaceAll(",", "")
        .split("\n");
    List<String> cleanBody = [];

    for (String line in tbody.clone()) {
      if (line
          .trim()
          .isNotEmpty) {
        cleanBody.add(line.trim());
      }
    }

    int itemIndex = 0;
    for (Map<String, Object> value in topics.values.first as Iterable) {
      topicList.add(MemoModelTopic(
          header: value["topic"].toString(),
          url: value["topicURL"].toString(),
          followerCount: int.parse(cleanBody[itemIndex + 3]),
          lastPost: cleanBody[itemIndex + 1],
          postCount: int.parse(cleanBody[itemIndex + 2])));
      itemIndex += 4;
    }
    return topicList;
  }

  void printCurrentMemoModelTopic(MemoModelTopic currentTopic) {
    print(currentTopic.header);
    print(currentTopic.url);
    print(currentTopic.followerCount);
    print(currentTopic.postCount);
    print(currentTopic.lastPost);
  }

  ScraperConfig createScraperConfigMemoModelPost() {
    return ScraperConfig(
      parsers: [
        Parser(
            id: "posts",
            parents: ["_root"],
            type: ParserType.element,
            selectors: [
              ".topic-post",
            ],
            multiple: true
        ),
        Parser(
            id: "msg",
            parents: ["posts"],
            type: ParserType.text,
            selectors: [
              ".message",
            ]
        ),
        Parser(
            id: "profileUrl",
            parents: ["posts"],
            type: ParserType.url,
            selectors: [
              ".profile",
            ]

        ),
        Parser(
            id: "age",
            parents: ["posts"],
            type: ParserType.text,
            selectors: [
              ".time",
            ]
        ),
        Parser(
            id: "likeCount",
            parents: ["posts"],
            type: ParserType.text,
            selectors: [
              ".like-info",
            ]
        ),
        Parser(
            id: "replyCount",
            parents: ["posts"],
            type: ParserType.text,
            selectors: [
              ".reply-count",
            ]
        ),
        Parser(
            id: "tipsInSatoshi",
            parents: ["posts"],
            type: ParserType.text,
            selectors: [
              ".tip-button",
            ]
        ),
        Parser(
            id: "created",
            parents: ["posts"],
            type: ParserType.attribute,
            selectors: [
              ".time::title",
            ]
        ),
        Parser(
            id: "txhash",
            parents: ["posts"],
            type: ParserType.url,
            selectors: [
              ".time",
            ]
        ),
        Parser(
            id: "creatorName",
            parents: ["posts"],
            type: ParserType.text,
            selectors: [
              ".profile",
            ]
        ),
        Parser(
            id: "imgur",
            parents: ["posts"],
            type: ParserType.attribute,
            selectors: [
              ".imgur::href",
            ]
        )
      ],
    );
  }

  List<MemoModelPost> createMemoModelPostList(Map<String, Object> posts,
      MemoModelTopic currentTopic) {
    List<MemoModelPost> postList = [];

    for (Map<String, Object> value in posts.values.first as Iterable) {
      var likeCount = 0;
      try {
        likeCount = int.parse(value["likeCount"].toString().split("\n")[0]);
      } catch (e) {}

      MemoModelPost memoModelPost = MemoModelPost(
          topic: currentTopic,
          text: value["msg"]?.toString(),
          age: value["age"].toString(),
          tipsInSatoshi: int.parse(
              (value["tipsInSatoshi"] ?? "0").toString().replaceAll(",", "")),
          likeCounter: likeCount,
          replyCounter: int.parse((value["replyCount"] ?? "0").toString()),
          created: value["created"].toString(),
          txHash: value["txhash"].toString().substring("/post".length),
          imageUrl: value["imgur"]?.toString(),
          creator: MemoModelCreator(name: value["creatorName"].toString(),
              id: value["profileUrl"].toString().substring(8)));

      extractYouTubeUrlAndRemoveJavaScriptFromText(memoModelPost);

      if (memoModelPost.videoUrl == null && memoModelPost.imageUrl == null) {
        continue;
      }

      postList.add(memoModelPost);
    }

    currentTopic.posts = postList;
    return postList;
  }

  void extractYouTubeUrlAndRemoveJavaScriptFromText(MemoModelPost memoModelPost) {
    String text = memoModelPost.text ?? "";
    String trigger = "MemoApp.YouTube.AddPlayer('";
    if (text.contains(trigger)) {
      int iTrigger = text.indexOf(trigger);
      int iStart = text.indexOf(', ', iTrigger);
      int iOptional = text.indexOf("?", iStart);
      int iEnd = text.indexOf("');", iStart);
      memoModelPost.videoUrl =
              text.substring(iStart + "', '".length - 1,
                 iOptional == -1 ? iEnd : iOptional);
      memoModelPost.text = text.replaceRange(iTrigger, iEnd + 3, "");
    }
  }

  void printMemoModelPost(List<MemoModelPost> postList) {
    for (MemoModelPost p in postList) {
      print(p.text ?? "");
      print(p.imageUrl ?? "");
      print(p.videoUrl ?? "");
      print(p.creator!.name);
      print(p.creator!.id);
      print(p.txHash);
      print(p.age);
      print(p.created);
    }
  }

  void cacheData(String key, String data) async {
    // print("CACHEDATA" + data);
    SharedPreferencesAsync().setString(key, data);
  }

  Future<String?> loadCachedData(String key) async {
    // print("LOADDATA" + key);
    String? data = await SharedPreferencesAsync().getString(key);
    return data;
  }
}