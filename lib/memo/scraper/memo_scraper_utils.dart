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
      'memo_session_id': 'a364ea48847c334abec911a8635ba3afbc1c883b3b07691877a4d3ffb784ce9e',
      // 'cf_clearance':
      //     'Uq297M5c3k3Hi8dbGtYFWE4i8paNI.PdeMWRpAJiGSI-1757609001-1.2.1.1-d5pGOZe0d1YVPIJOTK6QnVbD0Qm9rVN5Ly0Rf5ZLTHP200AX5dFE946DC3xpXT6xjRJqX2uu56Uyhh9lg3EjTulHA6FKVFQNxerkQSk.pJGrTFvyqzAcpRVmD7Yx.EMavZPND8oBtOlQmgLdFDemJK3Vj98WlJlGMtxrLN5cceKMTXDuObFOtiwBk9mSLKSAm_.8xaus7a.gMq1OCfQhoyKPqW7mfifplCC2M_d_0as',
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
    }
  }

  static MemoModelPost linkReferencesAndSetId(MemoModelPost post, {String? topicId, required String creatorId}) {
    post.text = post.text ?? "";
    // if (post.uniqueContentId!.contains("post")) {
    //   post.uniqueContentId = post.uniqueContentId!.substring("post/".length);
    // }
    // post.id = post.uniqueContentId!;
    // post.topicId = topic != null ? topic.id : "";
    post.topicId = topicId ?? "";
    post.creatorId = creatorId;
    MemoScraperUtil.extractUrlsAndHashtags(post);
    post.ipfsCid = MemoRegExp(post.text!).extractIpfsCid();
    post.imageUrl = MemoRegExp(post.text!).extractFirstWhitelistedImageUrl();
    post.videoUrl = MemoRegExp(post.text!).extractOdyseeUrl();
    // post.tagIds = post.tagIds;
    // post.topic = topic;
    try {
      // Attempt to parse the date string.
      post.createdDateTime = DateTime.parse(post.created!);
    } catch (e) {
      // If parsing fails, set the current time as a fallback.
      print("${post.created} is not a valid date string. Error parsing created string: $e. Using current time as fallback.");
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
    MemoScraperUtil.extractYouTubeUrlAndRemoveJavaScriptFromText(post);
    post.tagIds = List.from(MemoRegExp.extractHashtags(post.text));
    post.urls = List.from(MemoRegExp.extractUrlsWithHttpsAlways(post.text));
  }
}
