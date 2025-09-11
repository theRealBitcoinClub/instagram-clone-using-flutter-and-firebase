# generate_config.sh

# Source the configuration file to load the variables
source config.sh

# -----------------
# Generate IPFS file
# -----------------
echo "// lib/config_whitelist.dart
// This file is auto-generated. Do not edit.

class WhitelistMediaDomains {
  static const String imgur = r'^(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)$';
  static const String giphy = r'^(?:https?:\/\/)?(?:[^.]+\.)?giphy\.com(\/.*)?$';
  static const String domains = r'^https?://(?:[a-zA-Z0-9-]+\.)*(?:mahakka\.com|therealbitcoin\.club|memo\.cash|bmap\.app|bitcoinmap\.cash|yayalla\.com|papunto\.com)(?::\d+)?/.*$';
  static const String psfIpfs = r'^https?://free-bch\.fullstack\.cash/ipfs/view/([a-zA-Z0-9]{46,})(?:/.*)?$';
  static const String odysee = r'^https?://(?:www\.)?odysee\.com/(?:(?:@[^/]+/)?(?:\$\/)?(?:embed\/)?|@[^/]+\:)?([a-z0-9_-]+)(?::([a-f0-9]+))?(?:[?&].*)?$';
  static const String youtube = r'^https?://(?:www\.|m\.)?(?:youtube\.com/(?:(?:watch\?v=|embed/|v/|shorts/|live/|playlist\?.*v=)|(?:user/|channel/|c/)[^/]+/?(?:\?.*)?$)|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})(?:[?&].*)?$';
  static const String github = r'^https?://(?:[a-zA-Z0-9-]+\.)*github(?:usercontent)?\.com/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?$';
  static const String gitlab = r'^https?://(?:[a-zA-Z0-9-]+\.)*gitlab(?:\.com|\.io|\.net)?/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg|ico)(?:\?.*)?$';
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