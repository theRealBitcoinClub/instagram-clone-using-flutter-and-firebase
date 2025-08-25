// import 'package:mahakka/dart_web_scraper/common/enums.dart';
// import 'package:mahakka/dart_web_scraper/common/models/parser_model.dart';
// import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
// import 'package:mahakka/memoscraper/memo_scraper_utils.dart';
//
// import '../memomodel/memo_model_creator.dart';
//
// class MemoScraperCreator {
//   void startScrapeCreators(List<String> orderBy) async {
//     for (String order in orderBy) {
//       List<MemoModelCreator> creators = await scrapeCreators(order);
//       for (MemoModelCreator creator in creators) {
//         await loadCreatorNameAndText(creator.id, creator: creator);
//       }
//       // print("object");
//     }
//   }
//
//   Future<MemoModelCreator> loadCreatorNameAndText(String id, {MemoModelCreator? creator, bool nocache = false}) async {
//     Map<String, Object> data = await MemoScraperUtil.createScraper(
//       "profile/${id}",
//       createConfigCreatorDetails(),
//       nocache: nocache,
//     );
//
//     var split = data.values.first.toString().replaceAll(" ", "").split("\n");
//     split.removeWhere((element) => element.isEmpty);
//
//     MemoModelCreator result = creator == null ? MemoModelCreator() : creator;
//
//     result.name = split[0];
//     result.profileText = split[1];
//
//     return result;
//   }
//
//   ScraperConfig createConfigCreatorDetails() {
//     return ScraperConfig(
//       parsers: [
//         Parser(id: "nameAndText", parents: ["_root"], type: ParserType.text, selectors: [".title"]),
//       ],
//     );
//   }
//
//   Future<List<MemoModelCreator>> scrapeCreators(String sortedBy) async {
//     Map<String, Object> users = await MemoScraperUtil.createScraper("profiles${sortedBy}", createConfigCreators());
//     List<MemoModelCreator> creators = [];
//
//     List<dynamic> items = users.values.first as List<dynamic>;
//     for (Map<String, Object> item in items) {
//       List<String> stats = item["stats"] as List<String>;
//       MemoModelCreator creator = MemoModelCreator(
//         id: item["id"].toString().substring("profile".length + 1),
//         followerCount: int.parse(stats[2].replaceAll(",", '')),
//         actions: int.parse(stats[1].replaceAll(",", '')),
//         created: stats[3],
//         lastActionDate: stats[4],
//       );
//       creators.add(creator);
//     }
//     // print("object");
//     return creators;
//   }
//
//   ScraperConfig createConfigCreators() {
//     return ScraperConfig(
//       parsers: [
//         Parser(id: "users", parents: ["_root"], type: ParserType.element, selectors: ["tr"], multiple: true),
//         Parser(id: "id", parents: ["users"], type: ParserType.attribute, selectors: ["a::href"]),
//         Parser(multiple: true, id: "stats", parents: ["users"], type: ParserType.text, selectors: ["td"]),
//       ],
//     );
//   }
// }
