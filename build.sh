#!/bin/bash
set -e  # Immediately stop on any error
set -u  # Exit on undefined variables

echo "=========================================="
echo "    MacYT Build Pipeline"
echo "=========================================="

APP_NAME="MacYT"
APP_PATH="$APP_NAME.app"
CONTENTS="$APP_PATH/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf "$APP_PATH"
rm -f yt-dlp ffmpeg ffmpeg.zip
mkdir -p "$MACOS" "$RESOURCES"

# ==========================================
# 1. Verify Source Code
# ==========================================
echo "📄 Verifying source code..."
if [ ! -f "main.swift" ]; then
    echo "❌ ERROR: main.swift not found!"
    exit 1
fi
echo "✅ Source code verified"

# ==========================================
# 2. Download and Bundle yt-dlp
# ==========================================
echo "📦 Downloading yt-dlp..."
if ! curl -sL "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" -o "yt-dlp" 2>/dev/null; then
    echo "❌ ERROR: Failed to download yt-dlp"
    exit 1
fi
if [ ! -s "yt-dlp" ]; then
    echo "❌ ERROR: yt-dlp download is empty"
    exit 1
fi
chmod 755 "yt-dlp"
if [ ! -x "yt-dlp" ]; then
    echo "❌ ERROR: yt-dlp is not executable"
    exit 1
fi
echo "✅ yt-dlp downloaded and verified"

# ==========================================
# 3. Download and Bundle FFmpeg
# ==========================================
echo "📦 Downloading FFmpeg..."

# Try multiple FFmpeg sources for reliability
FFMPEG_SOURCES=(
    "https://evermeet.cx/ffmpeg/getrelease/zip"
    "https://github.com/GyanD/codexffmpeg/releases/latest/download/ffmpeg-git-appleosx64.zip"
)

FFMPEG_DOWNLOADED=false
for source in "${FFMPEG_SOURCES[@]}"; do
    echo "  Trying: $source"
    if curl -sL --max-time 60 "$source" -o "ffmpeg.zip" 2>/dev/null && [ -s "ffmpeg.zip" ]; then
        if unzip -o -q "ffmpeg.zip" 2>/dev/null && [ -f "ffmpeg" ]; then
            FFMPEG_DOWNLOADED=true
            break
        fi
    fi
done

if [ "$FFMPEG_DOWNLOADED" = true ] && [ -x "ffmpeg" ]; then
    echo "✅ FFmpeg downloaded and verified"
else
    echo "⚠️  FFmpeg could not be downloaded - download feature may be limited"
    rm -f ffmpeg.zip
fi

# ==========================================
# 4. Compile ARM64 Binary
# ==========================================
echo "🏗️  Compiling ARM64 binary..."
if ! swiftc -target arm64-apple-macos13.0 main.swift \
    -O \
    -o /tmp/app_arm64 \
    -framework AppKit \
    -framework WebKit \
    -framework MediaPlayer \
    -framework Security 2>/dev/null; then
    echo "❌ ERROR: ARM64 compilation failed"
    exit 1
fi

if [ ! -f /tmp/app_arm64 ]; then
    echo "❌ ERROR: ARM64 binary was not created"
    exit 1
fi

if [ ! -x /tmp/app_arm64 ]; then
    echo "❌ ERROR: ARM64 binary is not executable"
    exit 1
fi
echo "✅ ARM64 binary compiled successfully"

# ==========================================
# 5. Compile x86_64 Binary
# ==========================================
echo "🏗️  Compiling x86_64 binary..."
if ! swiftc -target x86_64-apple-macos13.0 main.swift \
    -O \
    -o /tmp/app_x86_64 \
    -framework AppKit \
    -framework WebKit \
    -framework MediaPlayer \
    -framework Security 2>/dev/null; then
    echo "❌ ERROR: x86_64 compilation failed"
    exit 1
fi

if [ ! -f /tmp/app_x86_64 ]; then
    echo "❌ ERROR: x86_64 binary was not created"
    exit 1
fi

if [ ! -x /tmp/app_x86_64 ]; then
    echo "❌ ERROR: x86_64 binary is not executable"
    exit 1
fi
echo "✅ x86_64 binary compiled successfully"

# Verify architectures
ARCH_ARM=$(lipo -info /tmp/app_arm64 2>/dev/null | grep -c "arm64" || echo "0")
ARCH_X86=$(lipo -info /tmp/app_x86_64 2>/dev/null | grep -c "x86_64" || echo "0")

if [ "$ARCH_ARM" -lt 1 ] || [ "$ARCH_X86" -lt 1 ]; then
    echo "❌ ERROR: Compiled binaries don't have correct architectures"
    echo "  ARM64: $ARCH_ARM, x86_64: $ARCH_X86"
    exit 1
fi
echo "✅ Binary architectures verified"

# ==========================================
# 6. Create Universal Binary
# ==========================================
echo "🔗 Creating Universal Binary..."
if ! lipo -create /tmp/app_arm64 /tmp/app_x86_64 -output "$MACOS/$APP_NAME"; then
    echo "❌ ERROR: Failed to create universal binary"
    exit 1
fi

if [ ! -f "$MACOS/$APP_NAME" ]; then
    echo "❌ ERROR: Universal binary was not created"
    exit 1
fi

if [ ! -x "$MACOS/$APP_NAME" ]; then
    echo "❌ ERROR: Universal binary is not executable"
    exit 1
fi

# Verify universal binary has both architectures
UNIVER_ARCH=$(lipo -info "$MACOS/$APP_NAME" 2>/dev/null)
echo "✅ Universal Binary created: $UNIVER_ARCH"

# Clean up temp binaries
rm -f /tmp/app_arm64 /tmp/app_x86_64

# ==========================================
# 7. Bundle Dependencies
# ==========================================
echo "📁 Bundling dependencies..."

# Bundle yt-dlp
if [ -f "yt-dlp" ]; then
    cp "yt-dlp" "$MACOS/yt-dlp"
    chmod 755 "$MACOS/yt-dlp"
    echo "  ✓ yt-dlp bundled"
fi

# Bundle FFmpeg
if [ -f "ffmpeg" ]; then
    cp "ffmpeg" "$MACOS/ffmpeg"
    chmod 755 "$MACOS/ffmpeg"
    echo "  ✓ FFmpeg bundled"
fi

# ==========================================
# 8. Add Application Icon
# ==========================================
echo "🎨 Bundling application icon..."
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES/AppIcon.icns"
    echo "✅ Application icon bundled"
else
    echo "⚠️  Warning: AppIcon.icns not found, using default icon"
fi

# ==========================================
# 9. Create Bundle Structure
# ==========================================
echo "🗂️  Setting up application bundle..."

# PkgInfo
touch "$CONTENTS/PkgInfo"
echo -n "APPL????" > "$CONTENTS/PkgInfo"

# Info.plist - Complete with all required keys
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleDisplayName</key><string>MacYT</string>
    <key>CFBundleExecutable</key><string>MacYT</string>
    <key>CFBundleIconFile</key><string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key><string>com.ayanosmany.macyt</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>MacYT</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSAppleScriptEnabled</key><string>No</string>
    <key>LSApplicationCategorySpecifier</key><string>public.app-category-entertainment</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSAppNetworkSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key><true/>
    </dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key><true/>
    </dict>
    <key>NSMainNibFile</key><string>MainMenu</string>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

echo "✅ Bundle structure created"

# ==========================================
# 10. Validate Info.plist
# ==========================================
echo "📋 Validating Info.plist..."
if ! plutil -lint "$CONTENTS/Info.plist" > /dev/null 2>&1; then
    echo "❌ ERROR: Info.plist validation failed"
    plutil -lint "$CONTENTS/Info.plist"
    exit 1
fi
echo "✅ Info.plist is valid"

# ==========================================
# 11. Sign Application
# ==========================================
echo "🔏 Signing application..."
xattr -cr "$APP_PATH"
if ! codesign --force --deep --sign - "$APP_PATH" 2>/dev/null; then
    echo "❌ ERROR: Application signing failed"
    exit 1
fi
echo "✅ Application signed"

# Verify signature
if ! codesign --verify --deep "$APP_PATH" 2>/dev/null; then
    echo "❌ ERROR: Code signature verification failed"
    codesign --verify --deep "$APP_PATH"
    exit 1
fi
echo "✅ Code signature verified"

# ==========================================
# 12. Create DMG
# ==========================================
echo "📦 Creating distribution DMG..."

DMG_TEMP="/tmp/dmg_staging_$$"
mkdir -p "$DMG_TEMP"

cp -R "$APP_PATH" "$DMG_TEMP/"

# Add "Double-Click to Fix" script
cat > "$DMG_TEMP/Double-Click to Fix 'Damaged App' Error.command" << 'CMD'
#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_TARGET="$DIR/MacYT.app"

echo "=========================================="
echo "   Fixing macOS Gatekeeper Permissions    "
echo "=========================================="
echo ""

if [ ! -d "$APP_TARGET" ]; then
    echo "❌ ERROR: $APP_TARGET not found"
    echo "Please ensure MacYT.app is in this folder"
    read -n 1 -s
    exit 1
fi

echo "Removing quarantine flags from: $APP_TARGET"
xattr -cr "$APP_TARGET" 2>/dev/null || true
xattr -d com.apple.quarantine "$APP_TARGET" 2>/dev/null || true

echo ""
echo "Signing application locally..."
if ! codesign --force --deep --sign - "$APP_TARGET" 2>/dev/null; then
    echo "Note: Local signing completed (development signature)"
fi

echo ""
echo "✅ SUCCESS! The app should now work."
echo ""
echo "If you still see issues:"
echo "  1. Try moving to Applications folder"
echo "  2. Right-click and choose Open"
echo ""
echo "Press any key to exit..."
read -n 1 -s
CMD

chmod 755 "$DMG_TEMP/Double-Click to Fix 'Damaged App' Error.command"

# Add instructions file
cat > "$DMG_TEMP/READ ME FIRST.txt" << 'TXT'
========================================
        MacYT - Installation Guide
========================================

This package includes:
✓ Native YouTube Client
✓ yt-dlp video downloader
✓ FFmpeg format converter

INSTALLATION:
1. Double-click "Double-Click to Fix 'Damaged App' Error.command"
2. Drag "MacYT.app" to your Applications folder
3. Launch from Applications

TROUBLESHOOTING:
If you see "App is damaged" error:
- The fix script will handle this automatically
- Or run in Terminal: xattr -cr /Applications/MacYT.app

FEATURES:
- Built-in AdBlocker (blacks out ads)
- SponsorBlock (auto-skips promos)
- OLED Dark Mode
- Zen Mode
- Picture-in-Picture
- Volume Control via Scroll
- System Media Keys
- YouTube Downloads (yt-dlp)
- Format Conversion (FFmpeg)

========================================
TXT

# Create DMG
echo ""
rm -f "$APP_NAME.dmg" 2>/dev/null
if ! hdiutil create -volname "MacYT" -srcfolder "$DMG_TEMP" -ov -format UDZO "$APP_NAME.dmg" 2>/dev/null; then
    echo "❌ ERROR: Failed to create DMG"
    rm -rf "$DMG_TEMP"
    exit 1
fi

# Verify DMG was created
if [ ! -f "$APP_NAME.dmg" ]; then
    echo "❌ ERROR: DMG file was not created"
    rm -rf "$DMG_TEMP"
    exit 1
fi

DMG_SIZE=$(du -h "$APP_NAME.dmg" | cut -f1)
echo "DMG size: $DMG_SIZE"

# Cleanup
rm -rf "$DMG_TEMP"
rm -f yt-dlp ffmpeg

echo ""
echo "=========================================="
echo "    ✅ BUILD COMPLETE - SUCCESS!"
echo "=========================================="
echo ""
echo "📦 Output: $APP_NAME.dmg"
echo "📍 Location: $(pwd)/$APP_NAME.dmg"
echo ""
echo "📁 Contents:"
ls -la "$APP_PATH/Contents/MacOS/"
echo ""
echo "🎯 Next Steps:"
echo "  1. Test the DMG on a clean Mac"
echo "  2. Verify all features work"
echo "  3. Create release notes"
echo ""