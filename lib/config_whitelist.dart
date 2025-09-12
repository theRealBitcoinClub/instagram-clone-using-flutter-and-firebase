// lib/config_whitelist.dart
// This file is auto-generated. Do not edit.

const whitelistPatterns = [
  WhitelistMediaDomains.imgur,
  WhitelistMediaDomains.giphy,
  WhitelistMediaDomains.domains,
  WhitelistMediaDomains.psfIpfs,
  WhitelistMediaDomains.odysee,
  WhitelistMediaDomains.youtube,
  WhitelistMediaDomains.github,
  WhitelistMediaDomains.gitlab,
  WhitelistMediaDomains.reddit,
  WhitelistMediaDomains.redditImages,
  WhitelistMediaDomains.twitter,
  WhitelistMediaDomains.twitterInternal,
  WhitelistMediaDomains.twitterImages,
  WhitelistMediaDomains.telegram,
];

class WhitelistMediaDomains {
  static const String imgur = r'(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)';
  static const String giphy = r'(?:https?:\/\/)?(?:[^.]+\.)?giphy\.com(\/.*)?';
  static const String domains = r'https?://(?:[a-zA-Z0-9-]+\.)*(?:read\.cash|mahakka\.com|therealbitcoin\.club|memo\.cash|bmap\.app|bitcoinmap\.cash|yayalla\.com|papunto\.com)(?::\d+)?/.*';
  static const String psfIpfs = r'https?://free-bch\.fullstack\.cash/ipfs/view/([a-zA-Z0-9]{46,})(?:/.*)?';
  static const String odysee = r'https?://(?:www\.)?odysee\.com/(?:(?:@[^/]+/)?(?:$\/)?(?:embed\/)?|@[^/]+\:)?([a-z0-9_-]+)(?::([a-f0-9]+))?(?:[?&].*)?';
  static const String youtube = r'\bhttps?://(?:www\.|m\.)?(?:youtube\.com/(?:(?:watch\?v=|embed/|v/|shorts/|live/|playlist\?.*\bv=)|(?:user/|channel/|c/)[^/\s]+/?(?:\?[^\s]*)?)|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})(?:[?&][^\s]*)?\b';
  static const String github = r'https?://(?:[a-zA-Z0-9-]+\.)*github(?:usercontent)?\.com/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?';
  static const String gitlab = r'https?://(?:[a-zA-Z0-9-]+\.)*gitlab(?:\.com|\.io|\.net)?/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?';
  static const String reddit = r'https?:\/\/(?:www\.|np\.)?reddit\.com\/r\/[a-zA-Z0-9_]+\/(?:comments|s)\/[a-zA-Z0-9_]+\/(?:\S+)?';
  static const String redditImages = r'https:\/\/(?:i\.redd\.it|preview\.redd\.it|external-preview\.redd\.it)\/(?:\S+\.(?:jpg|png|gif|gifv|jpeg|webp)|[a-zA-Z0-9]+)(?:\?.*)?';
  static const String twitter = r'https?:\/\/(?:www\.)?(?:twitter\.com|x\.com)\/[a-zA-Z0-9_]+\/?(?:status\/\d+)?';
  static const String twitterInternal = r'https?:\/\/t\.co\/[a-zA-Z0-9]+';
  static const String twitterImages = r'https:\/\/pbs\.twimg\.com\/media\/[a-zA-Z0-9_-]+\.(?:jpg|png|gif|webp|jpeg)';
  static const String telegram = r'https?:\/\/(?:www\.)?(?:t\.me|telegram\.org|telegram\.me|telegram\.dog|telesco\.pe|web\.telegram\.org|api\.telegram\.org|core\.telegram\.org)\/?(?:[a-zA-Z0-9_-]+)?(?:\/\S+)?';
}
