import 'package:html/dom.dart';
import 'package:mahakka/dart_web_scraper/common/models/scraper_config_model.dart';
import 'package:mahakka/dart_web_scraper/dart_web_scraper/web_scraper.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoScraperUtil {
  static Future<Map<String, Object>> createScraper(String path, ScraperConfig cfg, {bool nocache = true, String? mockData}) async {
    return await _createScraperAny(nocache, path, cfg, mockData: mockData);
  }

  static dynamic createScraperObj(String path, ScraperConfig cfg, {bool nocache = true}) async {
    return await _createScraperAny(nocache, path, cfg);
  }

  static Future<Map<String, Object>> _createScraperAny(bool nocache, String path, ScraperConfig cfg, {mockData}) async {
    String baseUrl = "https://memo.cash/";
    WebScraper webScraper = WebScraper();
    String? cachedData = nocache ? null : await loadCachedData(path);

    if (mockData != null) cachedData = mockData;

    // Brave browser user-agent
    const String braveUserAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

    // MANUALLY EXTRACTED COOKIES FROM BRAVE - REPLACE WITH YOUR COOKIES
    // Get these from SQLiteBrowser by running:
    // sqlite3 ~/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/Default/Cookies "SELECT name, value FROM cookies WHERE host_key LIKE '%memo.cash%';"
    final Map<String, String> braveCookies = {
      // Example cookies - REPLACE THESE WITH YOUR ACTUAL COOKIES
      'memo_session_id': 'd85267162d6dc270196c94677632319726e0b8adc44877016057afcd8cb1685f',
      // 'cf_clearance':
      //     '72xfvgJMT5.tQoOakqcPG3vgKNZLODHEPVNtL5m6fDY-1758718396-1.2.1.1-hSvvby.7fR1u.yf5ExcQVxJJqZI8ZO00a5tBXfqyMzryc2Knq.kxIEJIMCR47Ly_S38TOzlls4VT5XzBgCeb6j2R_HUXqYLq8rOrCeyVxq7dGDFXttzPR7srerLyXe__etBcGfRMzqOymYl2CzyteMTgLlHsp1c76Hw1iaBILbjov7E1u.fqNU012fupLIMpl8SRk.xei4Y7EN1wBPMU7mI.mnjkx4VFDS6qLBO7zlc',
      // 'remember_token': 'your_remember_token_here',
      // Add other cookies you find for memo.cash
    };

    // Brave headers to mimic browser behavior
    final Map<String, String> braveHeaders = {
      'User-Agent': braveUserAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
    };

    Map<String, Object> topics = await webScraper.scrape(
      html: cachedData == null ? null : Document.html(cachedData),
      concurrentParsing: true,
      url: Uri.parse(baseUrl + path),
      scraperConfig: cfg,
      // headers: braveHeaders, // Add Brave headers
      cookies: braveCookies, // Add manually extracted cookies
      // userAgent: braveUserAgent, // Set Brave user-agent
      onCacheHtmlString: (data) => nocache ? null : cacheData(path, data),
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
      memoModelPost.youtubeId = text.substring(iStart + "', '".length - 1, iOptional == -1 ? iEnd : iOptional);
      memoModelPost.text = text.replaceRange(iTrigger, iEnd + 3, "");
      memoModelPost.text = "${memoModelPost.text} https://youtu.be/${memoModelPost.youtubeId}";
    }
  }

  static MemoModelPost linkReferencesAndSetId(MemoModelPost post, {String? topicId, required String creatorId}) {
    if (post.text != null && post.text!.contains("hosseinzoda")) {
      print(post.text);
    }
    post.text = post.text ?? "";
    post.topicId = topicId ?? "";
    post.creatorId = creatorId;
    MemoScraperUtil.extractUrlsAndHashtags(post);
    post.ipfsCid = MemoRegExp(post.text!).extractIpfsCid();
    post.imageUrl = MemoRegExp(post.text!).extractFirstWhitelistedImageUrl();
    post.videoUrl = MemoRegExp(post.text!).extractOdyseeUrl();
    if (post.imgurUrl != null) post.text = "${post.text!} ${post.imgurUrl!}";
    try {
      post.createdDateTime = DateTime.parse(post.created!).subtract(Duration(hours: 4));
    } catch (e) {
      post.createdDateTime = DateTime.now();
    }
    return post;
  }

  static void printMemoModelPost(List<MemoModelPost> postList) {
    for (MemoModelPost p in postList) {
      print(p.id);
      print(p.text ?? "");
      print(p.imgurUrl ?? "");
      print(p.youtubeId ?? "");
      print(p.creator!.name);
      print(p.creator!.id);
      print(p.age);
      print(p.created);
    }
  }

  static bool isTextOnly(MemoModelPost post) {
    return post.youtubeId == null && post.imgurUrl == null && post.topicId.isEmpty && post.tagIds.isEmpty && post.urls.isEmpty;
  }

  static void extractUrlsAndHashtags(MemoModelPost post) {
    post.text = post.text ?? "";
    List<String> extractUrlsGenerously = MemoRegExp.extractUrlsGenerously(post.text!);
    if (post.text!.isNotEmpty) post.text = StringUtils.ensureSpacesAroundMatches(post.text!, extractUrlsGenerously).trim();
    MemoScraperUtil.extractYouTubeUrlAndRemoveJavaScriptFromText(post);
    post.tagIds = List<String>.from(MemoRegExp.extractHashtags(post.text).take(3));
    post.urls = List.from(MemoRegExp.wrapWithHttpAlways(extractUrlsGenerously));
  }
}
