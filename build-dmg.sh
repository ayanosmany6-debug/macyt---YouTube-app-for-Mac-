#!/bin/bash
set -e

APP_NAME="YouTube for Mac"
SOURCE_DIR="/Users/ayanosmany/Desktop/youtube for mac"
DMG_NAME="$APP_NAME.dmg"
DMG_PATH="$SOURCE_DIR/$DMG_NAME"

echo "📦 Creating DMG for $APP_NAME..."

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create temporary directory for DMG contents
mkdir -p "$SOURCE_DIR/dmg_temp"
rm -rf "$SOURCE_DIR/dmg_temp"
mkdir -p "$SOURCE_DIR/dmg_temp"

# Copy app bundle to temp
cp -R "$SOURCE_DIR/$APP_NAME.app" "$SOURCE_DIR/dmg_temp/"

# Create DMG
echo "Creating DMG file..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$SOURCE_DIR/dmg_temp" \
    -ov -format UDZO \
    -keychainDisable "$DMG_PATH" 2>/dev/null

# Clean up temp
rm -rf "$SOURCE_DIR/dmg_temp"

# Get file size
SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo "✅ DMG created: $DMG_PATH"
echo "📁 File size: $SIZE"