// // utils/url_utils.dart
// import 'package:any_link_preview/any_link_preview.dart';
//
// class UrlUtils {
//   static bool isValidUrl(String url) {
//     return AnyLinkPreview.isValidLink(
//       url,
//       protocols: ['http', 'https'],
//       // Add any domain whitelist/blacklist if needed
//       // hostWhitelist: ['yourdomain.com'],
//       // hostBlacklist: ['spamdomain.com'],
//     );
//   }
//
//   static String? getFirstValidUrl(List<String> urls) {
//     for (final url in urls) {
//       if (isValidUrl(url)) {
//         return url;
//       }
//     }
//     return null;
//   }
// }
