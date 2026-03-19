#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="AudioTier"
BUNDLE_NAME="AudioTier.app"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/$BUNDLE_NAME"

echo "==> Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "==> Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp .build/release/AudioTier "$APP_DIR/Contents/MacOS/AudioTier"

# Copy Info.plist
cp Info.plist "$APP_DIR/Contents/Info.plist"

# Generate app icon
if [ -f "$PROJECT_DIR/scripts/generate-icon.sh" ]; then
    bash "$PROJECT_DIR/scripts/generate-icon.sh" "$APP_DIR/Contents/Resources"
fi

# Generate menu bar icon (18pt = 36px @2x), fit preserving aspect ratio
SOURCE_IMAGE="${SOURCE_IMAGE:-$HOME/Downloads/audiotier-removebg-preview.png}"
if [ -f "$SOURCE_IMAGE" ]; then
    sips --resampleHeight 36 "$SOURCE_IMAGE" --out "$APP_DIR/Contents/Resources/MenuBarIcon.png" > /dev/null
    echo "==> Menu bar icon generated"
fi

echo "==> App bundle created at: $APP_DIR"
echo ""
echo "To install: cp -r \"$APP_DIR\" /Applications/"
echo "To create DMG: bash scripts/build-dmg.sh"
