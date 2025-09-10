# generate_config.sh

# Source the configuration file to load the variables
source config.sh

# -----------------
# Generate Dart file
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
# Generate Dart file
# -----------------
echo "// lib/config.dart
// This file is auto-generated. Do not edit.

class FirestoreCollections {
  static const String posts = '$POSTS_COLLECTION';
  static const String metadata = '$METADATA_COLLECTION';
}" > lib/config.dart

# -----------------
# Generate .env file for functions
# -----------------
echo "# functions/.env.local
# This file is auto-generated. Do not edit.

POSTS_COLLECTION='$POSTS_COLLECTION'
METADATA_COLLECTION='$METADATA_COLLECTION'" > functions/.env.local

echo "Configuration files generated successfully!"