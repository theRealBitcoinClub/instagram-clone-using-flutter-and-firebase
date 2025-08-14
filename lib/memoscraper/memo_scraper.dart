import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:dart_web_scraper/common/enums.dart';
import 'package:dart_web_scraper/common/models/parser_model.dart';
import 'package:dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:dart_web_scraper/dart_web_scraper/web_scraper.dart';
import 'package:instagram_clone1/memoscraper/memo_transformation.dart';
import '../memomodel/memo_model_creator.dart';
import '../memomodel/memo_model_post.dart';
import '../memomodel/memo_model_topic.dart';
import 'electrum_websocket_service.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

void main() async {
  testMemoScraper();
}

void testMemoScraper() async {
  WebScraper webScraper = WebScraper();

  Map<String, Object> topics = await webScraper.scrape(
    url: Uri.parse("https://memo.cash/topics/all"),
    scraperConfig: createScraperConfigMemoModelTopic(),
  );

  List<MemoModelTopic> topicList = createMemoModelTopicList(topics);

  final config = createScraperConfigMemoModelPost();

  for (MemoModelTopic currentTopic in topicList) {
    printCurrentMemoModelTopic(currentTopic);

    Map<String, Object> posts = await webScraper.scrape(
      url: Uri.parse("https://memo.cash/${currentTopic.url!}"),
      scraperConfig: config,
    );

    List<MemoModelPost> postList = createMemoModelPostList(posts, currentTopic);

    printMemoModelPost(postList);
  }
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
    if (line.trim().isNotEmpty) {
      cleanBody.add(line.trim());
    }
  }
  
  int itemIndex = 0;
  for (Map<String, Object> value in topics.values.first as Iterable ) {
    topicList.add(MemoModelTopic(
        header: value["topic"].toString(),
        url: value["topicURL"].toString(),
        followerCount: int.parse(cleanBody[itemIndex+3]),
        lastPost: cleanBody[itemIndex+1],
        postCount: int.parse(cleanBody[itemIndex+2])));
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

List<MemoModelPost> createMemoModelPostList(Map<String, Object> posts, MemoModelTopic currentTopic) {
  List<MemoModelPost> postList = [];

  for (Map<String, Object> value in posts.values.first as Iterable ) {
    var likeCount = 0;
    try {
      likeCount = int.parse(value["likeCount"].toString().split("\n")[0]);
    } catch (e) {}

        MemoModelPost memoModelPost = MemoModelPost(
            topic: currentTopic,
            text: value["msg"]?.toString(),
            age: value["age"].toString(),
            tipsInSatoshi: int.parse((value["tipsInSatoshi"] ?? "0").toString().replaceAll(",", "")),
            likeCounter: likeCount,
            replyCounter: int.parse((value["replyCount"] ?? "0").toString()),
            created: value["created"].toString(),
            txHash: value["txhash"].toString().substring("/post".length),
            imageUrl: value["imgur"]?.toString(),
            creator: MemoModelCreator(name: value["creatorName"].toString(),
            id: value["profileUrl"].toString().substring(8)));

    String text = memoModelPost.text ?? "";
    String trigger = "MemoApp.YouTube.AddPlayer('";
    if (text.contains(trigger)) {
      int i = text.indexOf(', ');
      memoModelPost.videoUrl="https://www.youtube.com/watch?v="
          + text.substring(i+"', '".length-1,text.indexOf("');", i-1));
    }

    if (memoModelPost.videoUrl == null && memoModelPost.imageUrl == null)
      continue;

    postList.add(memoModelPost);
  }

  currentTopic.posts = postList;
  return postList;
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
