#!/bin/bash

# Script to replace studio64.vmoptions files with backups

set -e  # Exit on any error

# Check if input file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/new/studio64.vmoptions"
    echo "Please provide the path to the new studio64.vmoptions file"
    exit 1
fi

NEW_FILE="$1"

# Check if new file exists
if [ ! -f "$NEW_FILE" ]; then
    echo "Error: New file '$NEW_FILE' does not exist or is not a regular file"
    exit 1
fi

# Target files to replace
# can be found by executing "locate studio64.vmoptions" and "find / -name studio64.vmoptions"
TARGET_FILES=(
    #"/home/pachamama/.config/Google/AndroidStudio2024.2/studio64.vmoptions"
    #"/home/pachamama/.config/Google/AndroidStudio2025.1.2/studio64.vmoptions"
    #"/home/pachamama/androidstudio/2025.1.2.11/android-studio/bin/studio64.vmoptions"
    #"/home/pachamama/androidstudio/android-studio/bin/studio64.vmoptions"
    "/opt/android-studio-2025.1.1/android-studio/bin/studio64.vmoptions"
)

echo "=== Studio64.vmoptions Replacement Script ==="
echo "New file: $NEW_FILE"
echo ""

SUCCESS_COUNT=0
SKIP_COUNT=0
ERROR_COUNT=0

for target_file in ${TARGET_FILES[@]}; do
    echo "Processing: $target_file"

    # Check if target file exists
    if [ ! -f "$target_file" ]; then
        echo "  ⚠️  Skipping: Target file does not exist"
        ((SKIP_COUNT++))
        echo ""
        continue
    fi

    # Check if we have write permission to the directory
    target_dir=$(dirname "$target_file")
    if [ ! -w "$target_dir" ]; then
        echo "  ⚠️  Skipping: No write permission to directory '$target_dir'"
        ((SKIP_COUNT++))
        echo ""
        continue
    fi

    # Create backup filename with timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_file="${target_file}.old_${timestamp}"

    # Create backup
    if cp "$target_file" "$backup_file"; then
        echo "  ✅ Backup created: $backup_file"
    else
        echo "  ❌ Error creating backup for $target_file"
        ((ERROR_COUNT++))
        echo ""
        continue
    fi

    # Replace the file
    if cp "$NEW_FILE" "$target_file"; then
        echo "  ✅ File replaced successfully"
        ((SUCCESS_COUNT++))
    else
        echo "  ❌ Error replacing file $target_file"
        # Try to restore from backup if replacement failed
        if cp "$backup_file" "$target_file"; then
            echo "  🔄 Restored original file from backup"
            rm "$backup_file"
        else
            echo "  ⚠️  Warning: Could not restore original file"
        fi
        ((ERROR_COUNT++))
    fi

    echo ""
done

# Summary
echo "=== Summary ==="
echo "Successful replacements: $SUCCESS_COUNT"
echo "Skipped (not found/no permission): $SKIP_COUNT"
echo "Errors: $ERROR_COUNT"
echo ""

if [ $SUCCESS_COUNT -gt 0 ]; then
    echo "✅ Replacement completed successfully for $SUCCESS_COUNT file(s)"
    echo "Remember to restart Android Studio for changes to take effect"
fi

if [ $ERROR_COUNT -gt 0 ]; then
    echo "❌ Some errors occurred during the process"
    exit 1
fi

exit 0