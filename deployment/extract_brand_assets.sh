#!/bin/sh

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <url to zip file with favicons>. See https://github.com/fazer-ai/chatwoot/blob/main/CUSTOM_BRANDING.md for more info."
  exit 1
fi

URL="$1"
TEMP_DIR=$(mktemp -d)
ZIP_FILE="$TEMP_DIR/downloaded_favicons.zip"
EXTRACT_DIR="$TEMP_DIR/extracted_favicons"
TARGET_DIR="public"

cleanup() {
  echo "Cleaning up temporary files..."
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Downloading zip file from $URL..."
if wget -q -O "$ZIP_FILE" "$URL"; then
  echo "Download successful."
else
  echo "Error: Failed to download file from $URL"
  exit 1
fi

echo "Creating extraction directory: $EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

echo "Unzipping $ZIP_FILE to $EXTRACT_DIR..."
if unzip -q "$ZIP_FILE" -d "$EXTRACT_DIR"; then
  echo "Unzip successful."
else
  echo "Error: Failed to unzip $ZIP_FILE"
  exit 1
fi

echo "Flattening all files from extracted archive…"
# Count files first for progress
FILE_COUNT=$(find "$EXTRACT_DIR" -type f | wc -l)
echo "Found $FILE_COUNT file(s) to extract"

# Use a safer method: copy files first, then remove source
# This avoids issues with mv when TARGET_DIR might be inside EXTRACT_DIR
COUNTER=0
find "$EXTRACT_DIR" -type f | while read -r file; do
  COUNTER=$((COUNTER + 1))
  filename=$(basename "$file")
  # Only show progress for every 10th file or last file
  if [ $((COUNTER % 10)) -eq 0 ] || [ $COUNTER -eq $FILE_COUNT ]; then
    echo "Extracting $COUNTER/$FILE_COUNT: $filename"
  fi
  cp -f "$file" "$TARGET_DIR/"
done

# Remove extracted directory after copying
rm -rf "$EXTRACT_DIR"

echo "Process completed. $FILE_COUNT file(s) extracted to $TARGET_DIR/"
