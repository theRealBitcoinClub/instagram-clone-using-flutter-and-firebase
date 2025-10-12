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

echo "🏗️  Building release APKs for all ABIs..."
flutter build apk --release --split-per-abi

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

# Define ABIs to process
ABIS=("armeabi-v7a" "arm64-v8a" "x86_64")

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

for ABI in "${ABIS[@]}"; do
    ORIGINAL_APK_PATH="build/app/outputs/flutter-apk/app-${ABI}-release.apk"

    if [ ! -f "$ORIGINAL_APK_PATH" ]; then
        echo "   ⚠️  No APK found for $ABI, skipping..."
        continue
    fi

    # Define new APK name with ABI
    NEW_APK_NAME="mahakka_com-${VERSION_NAME}-${ABI}.apk"
    NEW_APK_PATH="build/app/outputs/flutter-apk/${NEW_APK_NAME}"

    # Rename the APK file
    echo "   📝 Renaming $ABI APK to: $NEW_APK_NAME"
    mv "$ORIGINAL_APK_PATH" "$NEW_APK_PATH"

    # Calculate SHA256 checksum
    if command -v sha256sum &> /dev/null; then
        SHA256_CHECKSUM=$(sha256sum "$NEW_APK_PATH" | awk '{print $1}')
    else
        SHA256_CHECKSUM=$(shasum -a 256 "$NEW_APK_PATH" | awk '{print $1}')
    fi

    # Get file size
    FILE_SIZE=$(du -h "$NEW_APK_PATH" | cut -f1)

    # Create checksum file for this ABI
    CHECKSUM_FILE="$BUNDLE_DIR/checksum-${ABI}.txt"
    echo "$SHA256_CHECKSUM" > "$CHECKSUM_FILE"

    # Copy APK to bundle directory
    BUNDLED_APK_PATH="$BUNDLE_DIR/$NEW_APK_NAME"
    cp "$NEW_APK_PATH" "$BUNDLED_APK_PATH"

    echo "   📊 $ABI: $FILE_SIZE"
    echo "   🔐 SHA256: $SHA256_CHECKSUM"
    echo "   ✅ Created: $CHECKSUM_FILE"
    echo "   ✅ Bundled: $BUNDLED_APK_PATH"

    # Optional: Create a copy in the project root for easy access
    cp "$NEW_APK_PATH" "./$NEW_APK_NAME" 2>/dev/null && echo "   📋 Copy created at: ./$NEW_APK_NAME"
    echo ""
done

echo "=========================================="
echo "✅ RELEASE BUILDS SUCCESSFUL"
echo "🔢 Version: $VERSION_NAME (build $VERSION_CODE)"
echo "📁 APKs generated in: build/app/outputs/flutter-apk/"
echo "📦 Bundle created in: $BUNDLE_DIR/"
echo ""
echo "📋 Bundle Contents:"
ls -la "$BUNDLE_DIR/"
echo "=========================================="