import 'package:html/dom.dart';
import 'package:instagram_clone1/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:instagram_clone1/dart_web_scraper/dart_web_scraper/web_scraper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memomodel/memo_model_post.dart';

class MemoScraperUtil {

  static Future<Map<String, Object>> createScraper(String path, ScraperConfig cfg, {bool nocache = false}) async {
    String baseUrl = "https://memo.cash/";
    WebScraper webScraper = WebScraper();
    String? cachedData = nocache ? null : await loadCachedData(path);
    Map<String, Object> topics = await webScraper.scrape(
      html: cachedData == null ? null : Document.html(cachedData),
      concurrentParsing: true,
      url: Uri.parse(baseUrl + path),
      scraperConfig: cfg,
      onCacheHtmlString: (data) => cacheData(path, data),
    );
    return topics;
  }

  static void cacheData(String key, String data) async {
    // print("CACHEDATA" + data);
    SharedPreferencesAsync().setString(key, data);
  }

  static Future<String?> loadCachedData(String key) async {
    // print("LOADDATA" + key);
    String? data = await SharedPreferencesAsync().getString(key);
    return data;
  }

  static void extractYouTubeUrlAndRemoveJavaScriptFromText(MemoModelPost memoModelPost) {
    String text = memoModelPost.text ?? "";
    String trigger = "MemoApp.YouTube.AddPlayer('";
    if (text.contains(trigger)) {
      int iTrigger = text.indexOf(trigger);
      int iStart = text.indexOf(', ', iTrigger);
      int iOptional = text.indexOf("?", iStart);
      int iEnd = text.indexOf("');", iStart);
      memoModelPost.youtubeId =
          text.substring(iStart + "', '".length - 1,
              iOptional == -1 ? iEnd : iOptional);
      memoModelPost.text = text.replaceRange(iTrigger, iEnd + 3, "");
    }
  }

  static void printMemoModelPost(List<MemoModelPost> postList) {
    for (MemoModelPost p in postList) {
      print(p.text ?? "");
      print(p.imgurUrl ?? "");
      print(p.youtubeId ?? "");
      print(p.creator!.name);
      print(p.creator!.id);
      print(p.txHash);
      print(p.age);
      print(p.created);
    }
  }

  static List<String> extractUrls(String? text) {
    if (text == null || text.isEmpty)
      return [];

    Iterable<RegExpMatch> matches = RegExp(r'/(?:http[s]?:\/\/.)?(?:www\.)?[-a-zA-Z0-9@%._\+~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)', caseSensitive: false).allMatches(text);
    return convertRegExpMatchesToList(matches);
  }

  static List<String> extractHashtags(String? text) {
    if (text == null || text.isEmpty)
      return [];


    //TODO WHY ARE SOME POSTS WITH HASHTAGS THAT HAVE MISSING SPACES NOT SHOWING AS REPLIEABLE
    Iterable<RegExpMatch> matches = RegExp(r'(?:\s|^)(?:#(?!(?:\d+|\w+?_|_\w*?)(?:\s|$)))(\w+)(?=\s|$)', caseSensitive: false).allMatches(text);
    return convertRegExpMatchesToList(matches);
  }

  static List<String> convertRegExpMatchesToList(Iterable<RegExpMatch> matches) {
    if (matches.isEmpty)
      return [];
    
    List<String> results = [];
    for (var element in matches) {
      String match = element.input.substring(element.start, element.end);
      results.add(match.trim());
    }
    return results;
  }


  static bool isTextOnly(MemoModelPost post) {
    return post.youtubeId == null
        && post.imgurUrl == null
        && post.topic == null
        && post.hashtags.isEmpty;
  }

  static void extractUrlsAndHashtags(MemoModelPost post) {
    MemoScraperUtil.extractYouTubeUrlAndRemoveJavaScriptFromText(post);
    post.hashtags.addAll(MemoScraperUtil.extractHashtags(post.text));
    post.urls.addAll(MemoScraperUtil.extractUrls(post.text));
  }
}