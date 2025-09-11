// brave_scraper_utils.dart
class BraveScraperUtils {
  static const String braveUserAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  // Common Brave headers to mimic browser behavior
  static Map<String, String> getBraveHeaders({Map<String, String>? additionalCookies}) {
    final headers = {
      'User-Agent': braveUserAgent,
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
    };

    // Add cookies if provided
    if (additionalCookies != null && additionalCookies.isNotEmpty) {
      final cookieString = additionalCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      headers['Cookie'] = cookieString;
    }

    return headers;
  }

  // Example common cookies you might want to include
  static Map<String, String> getCommonBraveCookies() {
    return {
      'wide': '1',
      'YSC': 'browser-generated-value', // YouTube session cookie
      'VISITOR_INFO1_LIVE': 'browser-generated-value', // YouTube
      'PREF': 'f6=40000000', // YouTube preferences
      // Add other common cookies as needed
    };
  }
}
