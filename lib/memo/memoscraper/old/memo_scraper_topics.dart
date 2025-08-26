// import 'package:blockchain_utils/blockchain_utils.dart';
// import 'package:mahakka/dart_web_scraper/common/enums.dart';
// import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
// import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
// import 'package:mahakka/memoscraper/memo_scraper_utils.dart';
//
// import '../memomodel/memo_model_creator.dart';
// import '../memomodel/memo_model_post.dart';
// import '../memomodel/memo_model_topic.dart';
//
// class MemoScraperTopic {
//   Future<void> startScrapeTopics(String cacheId, int offset) async {
//     MemoModelTopic.topics.clear();
//     for (int off = offset; off >= 0; off -= 25) {
//       Map<String, Object> topics = await MemoScraperUtil.createScraper(
//         "topics/all?offset=$off&x=$cacheId",
//         createScraperConfigMemoModelTopic(),
//       );
//
//       List<MemoModelTopic> topicList = createMemoModelTopicList(topics);
//
//       MemoModelTopic.topics.addAll(topicList);
//       final config = createScraperConfigMemoModelPost();
//
//       for (MemoModelTopic currentTopic in topicList) {
//         // printCurrentMemoModelTopic(currentTopic);
//
//         Map<String, Object> posts = await MemoScraperUtil.createScraper("${currentTopic.url!}?x=$cacheId", config);
//
//         var postList = createTopicPostList(posts, currentTopic);
//         MemoModelPost.addToGlobalPostList(postList.reversed.toList());
//
//         // printMemoModelPost(postList);
//         // print("object");
//         print("RUNNING SCRAPE TOPICccccc POSTS: ${currentTopic.header}");
//       }
//
//       print("FINISH SCRAPE TOPICS: $cacheId");
//     }
//   }
//
//   ScraperConfig createScraperConfigMemoModelTopic() {
//     return ScraperConfig(
//       parsers: [
//         Parser(id: "topics", parents: ["_root"], type: ParserType.element, selectors: ["td"], multiple: true),
//         Parser(id: "topic", parents: ["topics"], type: ParserType.text, selectors: ["a"]),
//         Parser(id: "topicURL", parents: ["topics"], type: ParserType.url, selectors: ["a"]),
//         Parser(id: "tbody", parents: ["_root"], type: ParserType.text, selectors: ["tbody"]),
//       ],
//     );
//   }
//
//   List<MemoModelTopic> createMemoModelTopicList(Map<String, Object> topics) {
//     List<MemoModelTopic> topicList = [];
//
//     var tbody = topics.values.elementAt(1).toString().replaceAll(",", "").split("\n");
//     List<String> cleanBody = [];
//
//     for (String line in tbody.clone()) {
//       if (line.trim().isNotEmpty) {
//         cleanBody.add(line.trim());
//       }
//     }
//
//     int itemIndex = 0;
//     for (Map<String, Object> value in topics.values.first as Iterable) {
//       topicList.add(
//         MemoModelTopic(
//           header: value["topic"].toString(),
//           url: value["topicURL"].toString(),
//           followerCount: int.parse(cleanBody[itemIndex + 3]),
//           lastPost: cleanBody[itemIndex + 1],
//           postCount: int.parse(cleanBody[itemIndex + 2]),
//         ),
//       );
//       itemIndex += 4;
//     }
//     return topicList;
//   }
//
//   void printCurrentMemoModelTopic(MemoModelTopic currentTopic) {
//     print(currentTopic.header);
//     print(currentTopic.url);
//     print(currentTopic.followerCount);
//     print(currentTopic.postCount);
//     print(currentTopic.lastPost);
//   }
//
//   ScraperConfig createScraperConfigMemoModelPost() {
//     return ScraperConfig(
//       parsers: [
//         Parser(id: "posts", parents: ["_root"], type: ParserType.element, selectors: [".topic-post"], multiple: true),
//         Parser(id: "msg", parents: ["posts"], type: ParserType.text, selectors: [".message"]),
//         Parser(id: "profileUrl", parents: ["posts"], type: ParserType.url, selectors: [".profile"]),
//         Parser(id: "age", parents: ["posts"], type: ParserType.text, selectors: [".time"]),
//         Parser(id: "likeCount", parents: ["posts"], type: ParserType.text, selectors: [".like-info"]),
//         Parser(id: "replyCount", parents: ["posts"], type: ParserType.text, selectors: [".reply-count"]),
//         Parser(id: "tipsInSatoshi", parents: ["posts"], type: ParserType.text, selectors: [".tip-button"]),
//         Parser(id: "created", parents: ["posts"], type: ParserType.attribute, selectors: [".time::title"]),
//         Parser(id: "txhash", parents: ["posts"], type: ParserType.url, selectors: [".time"]),
//         Parser(id: "creatorName", parents: ["posts"], type: ParserType.text, selectors: [".profile"]),
//         Parser(id: "imgur", parents: ["posts"], type: ParserType.attribute, selectors: [".imgur::href"]),
//       ],
//     );
//   }
//
//   List<MemoModelPost> createTopicPostList(Map<String, Object> posts, MemoModelTopic topic) {
//     List<MemoModelPost> postList = [];
//
//     for (Map<String, Object> item in posts.values.first as Iterable) {
//       var likeCount = 0;
//       try {
//         likeCount = int.parse(item["likeCount"].toString().split("\n")[0]);
//       } catch (e) {}
//
//       MemoModelPost post = MemoModelPost(
//         topic: topic,
//         text: item["msg"]?.toString(),
//         age: item["age"].toString(),
//         tipsInSatoshi: int.parse((item["tipsInSatoshi"] ?? "0").toString().replaceAll(",", "")),
//         likeCounter: likeCount,
//         replyCounter: int.parse((item["replyCount"] ?? "0").toString()),
//         created: item["created"].toString(),
//         txHash: item["txhash"].toString().substring("/post".length),
//         imgurUrl: item["imgur"]?.toString(),
//         creator: MemoModelCreator(name: item["creatorName"].toString(), id: item["profileUrl"].toString().substring(8)),
//       );
//
//       MemoScraperUtil.extractUrlsAndHashtags(post);
//
//       if (MemoScraperUtil.isTextOnly(post)) {
//         continue;
//       }
//
//       postList.add(post);
//     }
//
//     topic.posts = postList;
//     return postList;
//   }
// }
