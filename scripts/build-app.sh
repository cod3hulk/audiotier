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

# Copy menu bar icon (pre-generated monochrome template)
MENUBAR_ICON="$PROJECT_DIR/assets/menubar-icon.png"
if [ -f "$MENUBAR_ICON" ]; then
    cp "$MENUBAR_ICON" "$APP_DIR/Contents/Resources/MenuBarIcon.png"
    echo "==> Menu bar icon copied"
fi

echo "==> App bundle created at: $APP_DIR"
echo ""
echo "To install: cp -r \"$APP_DIR\" /Applications/"
echo "To create DMG: bash scripts/build-dmg.sh"
