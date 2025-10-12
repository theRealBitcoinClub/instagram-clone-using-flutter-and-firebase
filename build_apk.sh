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

echo "🏗️  Building release APK..."
flutter build apk --release

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

# Find the generated APK file
ORIGINAL_APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$ORIGINAL_APK_PATH" ]; then
    echo "❌ Error: Could not find APK file at $ORIGINAL_APK_PATH"
    exit 1
fi

# Define new APK name
NEW_APK_NAME="mahakka_com-${VERSION_NAME}.apk"
NEW_APK_PATH="build/app/outputs/flutter-apk/${NEW_APK_NAME}"

# Rename the APK file
echo "📦 Renaming APK to: $NEW_APK_NAME"
mv "$ORIGINAL_APK_PATH" "$NEW_APK_PATH"

# Calculate and print SHA256 checksum
echo "🔒 Calculating SHA256 checksum..."
if command -v sha256sum &> /dev/null; then
    SHA256_CHECKSUM=$(sha256sum "$NEW_APK_PATH" | awk '{print $1}')
else
    SHA256_CHECKSUM=$(shasum -a 256 "$NEW_APK_PATH" | awk '{print $1}')
fi

# Get file size
FILE_SIZE=$(du -h "$NEW_APK_PATH" | cut -f1)

echo ""
echo "=========================================="
echo "✅ RELEASE BUILD SUCCESSFUL"
echo "📁 APK: $NEW_APK_PATH"
echo "📊 Size: $FILE_SIZE"
echo "🔢 Version: $VERSION_NAME (build $VERSION_CODE)"
echo "🔐 SHA256: $SHA256_CHECKSUM"
echo "=========================================="

# Optional: Also create a copy in the project root for easy access
cp "$NEW_APK_PATH" "./$NEW_APK_NAME" 2>/dev/null && echo "📋 Copy created at: ./$NEW_APK_NAME"