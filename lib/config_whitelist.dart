// lib/config_whitelist.dart
// This file is auto-generated. Do not edit.

class WhitelistMediaDomains {
  static const String imgur = r'^(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)$';
  static const String giphy = r'^(?:https?:\/\/)?(?:[^.]+\.)?giphy\.com(\/.*)?$';
  static const String domains = r'^https?://(?:[a-zA-Z0-9-]+\.)*(?:mahakka\.com|therealbitcoin\.club|memo\.cash|bmap\.app|bitcoinmap\.cash|yayalla\.com|papunto\.com)(?::\d+)?/.*$';
  static const String psfIpfs = r'^https?://free-bch\.fullstack\.cash/ipfs/view/([a-zA-Z0-9]{46,})(?:/.*)?$';
  static const String odysee = r'^https?://(?:www\.)?odysee\.com/(?:(?:@[^/]+/)?(?:$\/)?(?:embed\/)?|@[^/]+\:)?([a-z0-9_-]+)(?::([a-f0-9]+))?(?:[?&].*)?$';
  static const String youtube = r'^https?://(?:www\.|m\.)?(?:youtube\.com/(?:(?:watch\?v=|embed/|v/|shorts/|live/|playlist\?.*v=)|(?:user/|channel/|c/)[^/]+/?(?:\?.*)?$)|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})(?:[?&].*)?$';
  static const String github = r'^https?://(?:[a-zA-Z0-9-]+\.)*github(?:usercontent)?\.com/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?$';
  static const String gitlab = r'^https?://(?:[a-zA-Z0-9-]+\.)*gitlab(?:\.com|\.io|\.net)?/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?$';
}
