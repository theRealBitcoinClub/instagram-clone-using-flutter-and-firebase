# generate_config.sh

# Source the configuration file to load the variables
source config.sh

# -----------------
# Generate IPFS file
# -----------------
echo "// lib/config_whitelist.dart
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
  static const String imgur = r'https?:\/\/(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)';
  static const String giphy = r'https?:\/\/(?:i\.|media\d*\.)?giphy\.com\/.*?\.(?:gif|webp|jpg|jpeg|png)(?:\?.*)?';
  static const String domains = r'https?://(?:[a-zA-Z0-9-]+\.)*(?:read\.cash|mahakka\.com|therealbitcoin\.club|memo\.cash|bmap\.app|bitcoinmap\.cash|yayalla\.com|papunto\.com)(?::\d+)?/.*';
  static const String psfIpfs = r'https?://free-bch\.fullstack\.cash/ipfs/view/([a-zA-Z0-9]{46,})(?:/.*)?';
  static const String odysee = r'https?://(?:www\.)?odysee\.com/@[^\s/]+:[^\s/]+/[^\s?]*(?::[^\s/?]+)?';
  static const String youtube = r'\bhttps?://(?:www\.|m\.)?(?:youtube\.com/(?:(?:watch\?v=|embed/|v/|shorts/|live/|playlist\?.*\bv=)|(?:user/|channel/|c/)[^/\s]+/?(?:\?[^\s]*)?)|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})(?:[?&][^\s]*)?\b';
  static const String github = r'https?://(?:[a-zA-Z0-9-]+\.)*github(?:usercontent)?\.com/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?';
  static const String gitlab = r'https?://(?:[a-zA-Z0-9-]+\.)*gitlab(?:\.com|\.io|\.net)?/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?';
  static const String reddit = r'https?:\/\/(?:www\.|np\.)?reddit\.com\/r\/[a-zA-Z0-9_]+\/(?:comments|s)\/[a-zA-Z0-9_]+\/(?:\S+)?';
  static const String redditImages = r'https?:\/\/(?:i\.redd\.it|preview\.redd\.it|external-preview\.redd\.it)\/(?:\S+\.(?:jpg|png|gif|gifv|jpeg|webp)|[a-zA-Z0-9]+)(?:\?.*)?';
  static const String twitter = r'https?:\/\/(?:www\.)?(?:twitter\.com|x\.com)\/[a-zA-Z0-9_]+\/?(?:status\/\d+)?';
  static const String twitterInternal = r'https?:\/\/t\.co\/[a-zA-Z0-9]+';
  static const String twitterImages = r'https?:\/\/pbs\.twimg\.com\/media\/[a-zA-Z0-9_-]+\.(?:jpg|png|gif|webp|jpeg)';
  static const String telegram = r'https?:\/\/(?:www\.)?(?:t\.me|telegram\.org|telegram\.me|telegram\.dog|telesco\.pe|web\.telegram\.org|api\.telegram\.org|core\.telegram\.org)\/?(?:[a-zA-Z0-9_-]+)?(?:\/\S+)?';
}" > lib/config_whitelist.dart

# -----------------
# Generate IPFS file
# -----------------
echo "// lib/config_ipfs.dart
// This file is auto-generated. Do not edit.

class IpfsConfig {
  static const String metadataFile = '$IPFS_METADATA_FILE';
  static const String mappingFile = '$IPFS_MAPPING_FILE';
  static const String ghToken = '$IPFS_GH_TOKEN';
  static const String ghRepo = '$IPFS_GH_REPO';
}" > lib/config_ipfs.dart

# -----------------
# Generate Firebase Dart file
# -----------------
echo "// lib/config.dart
// This file is auto-generated. Do not edit.

class FirestoreCollections {
  static const String topic = '$TOPIC_COLLECTION';
  static const String user = '$USER_COLLECTION';
  static const String tag = '$TAG_COLLECTION';
  static const String creator = '$CREATOR_COLLECTION';
  static const String posts = '$POSTS_COLLECTION';
  static const String metadata = '$METADATA_COLLECTION';
}" > lib/config.dart

# -----------------
# Generate Firebase .env file for functions
# -----------------
echo "# functions/.env.local
# This file is auto-generated. Do not edit.

POSTS_COLLECTION='$POSTS_COLLECTION'
METADATA_COLLECTION='$METADATA_COLLECTION'" > functions/.env.local

echo "Configuration files generated successfully!"