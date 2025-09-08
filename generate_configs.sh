# generate_config.sh

# Source the configuration file to load the variables
source config.sh

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