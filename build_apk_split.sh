#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🧪 Running Flutter tests..."
if flutter test; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed. Build aborted."
    exit 1
fi

echo "🏗️  Building release APKs for all ABIs with ABI environment variables..."

# Create temp directory for builds
TEMP_BUILD_DIR="temp_builds"
mkdir -p "$TEMP_BUILD_DIR"

# Define ABIs to process with their build parameters
declare -A ABI_CONFIG=(
    ["armeabi-v7a"]="android-arm --dart-define=ABI=armeabi-v7a"
    ["arm64-v8a"]="android-arm64 --dart-define=ABI=arm64-v8a"
    ["x86_64"]="android-x64 --dart-define=ABI=x86_64"
)

# Build each ABI separately with its environment variable
for ABI in "${!ABI_CONFIG[@]}"; do
    BUILD_PARAMS=${ABI_CONFIG[$ABI]}
    echo ""
    echo "🔨 Building $ABI..."

    # Clean the build directory before each build
    rm -rf build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || true

    # Build the APK
    flutter build apk --release --target-platform $BUILD_PARAMS

    # Move the built APK to temp directory with ABI name
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        TEMP_APK_PATH="$TEMP_BUILD_DIR/app-${ABI}-release.apk"
        mv "build/app/outputs/flutter-apk/app-release.apk" "$TEMP_APK_PATH"
        echo "   ✅ Built and moved to: $TEMP_APK_PATH"
    else
        echo "   ❌ Build failed for $ABI - no APK produced"
    fi
done

# Extract version information from pubspec.yaml
echo "📋 Extracting version information..."
VERSION_NAME=$(grep 'version:' pubspec.yaml | sed 's/version: //' | sed 's/\+.*//' | tr -d ' ')
VERSION_CODE=$(grep 'version:' pubspec.yaml | sed 's/.*+//' | tr -d ' ')

if [ -z "$VERSION_NAME" ] || [ -z "$VERSION_CODE" ]; then
    echo "❌ Error: Could not extract version information from pubspec.yaml"
    echo "   Make sure your version line looks like: 'version: 1.0.0+1'"
    exit 1
fi

echo "   Version Name: $VERSION_NAME"
echo "   Version Code: $VERSION_CODE"

# Create version folder for bundled output
BUNDLE_DIR="release_bundles/$VERSION_NAME"
echo ""
echo "📁 Creating bundle directory: $BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"

# Create version.txt file
echo "$VERSION_NAME" > "$BUNDLE_DIR/version.txt"
echo "   ✅ Created: $BUNDLE_DIR/version.txt"

echo ""
echo "📦 Processing APKs for each ABI:"

for ABI in "${!ABI_CONFIG[@]}"; do
    TEMP_APK_PATH="$TEMP_BUILD_DIR/app-${ABI}-release.apk"

    if [ ! -f "$TEMP_APK_PATH" ]; then
        echo "   ❌ No APK found for $ABI at $TEMP_APK_PATH, skipping..."
        continue
    fi

    # Define new APK name with ABI
    NEW_APK_NAME="mahakka_com-${VERSION_NAME}-${ABI}.apk"
    FINAL_APK_PATH="$BUNDLE_DIR/$NEW_APK_NAME"

    # Copy APK to bundle directory with final name
    echo "   📝 Copying $ABI APK to: $NEW_APK_NAME"
    cp "$TEMP_APK_PATH" "$FINAL_APK_PATH"

    # Calculate SHA256 checksum
    if command -v sha256sum &> /dev/null; then
        SHA256_CHECKSUM=$(sha256sum "$FINAL_APK_PATH" | awk '{print $1}')
    else
        SHA256_CHECKSUM=$(shasum -a 256 "$FINAL_APK_PATH" | awk '{print $1}')
    fi

    # Get file size
    FILE_SIZE=$(du -h "$FINAL_APK_PATH" | cut -f1)

    # Create checksum file for this ABI
    CHECKSUM_FILE="$BUNDLE_DIR/checksum-${ABI}.txt"
    echo "$SHA256_CHECKSUM" > "$CHECKSUM_FILE"

    echo "   📊 $ABI: $FILE_SIZE"
    echo "   🔐 SHA256: $SHA256_CHECKSUM"
    echo "   ✅ Created: $CHECKSUM_FILE"
    echo "   ✅ Bundled: $FINAL_APK_PATH"

    # Optional: Create a copy in the project root for easy access
    cp "$FINAL_APK_PATH" "./$NEW_APK_NAME" 2>/dev/null && echo "   📋 Copy created at: ./$NEW_APK_NAME"
    echo ""
done

# Clean up temp directory
rm -rf "$TEMP_BUILD_DIR"
echo "🧹 Cleaned up temporary build files"

echo "=========================================="
echo "✅ RELEASE BUILDS SUCCESSFUL"
echo "🔢 Version: $VERSION_NAME (build $VERSION_CODE)"
echo "📦 Bundle created in: $BUNDLE_DIR/"
echo ""
echo "📋 Bundle Contents:"
ls -la "$BUNDLE_DIR/"
echo "=========================================="