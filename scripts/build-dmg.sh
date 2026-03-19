#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="AudioTier"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="AudioTier-1.0.0.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
STAGING_DIR="$BUILD_DIR/dmg-staging"

# Build the app first if needed
if [ ! -d "$APP_DIR" ]; then
    echo "==> App bundle not found, building first..."
    bash "$SCRIPT_DIR/build-app.sh"
fi

echo "==> Creating DMG..."

# Clean up
rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

# Copy app to staging
cp -R "$APP_DIR" "$STAGING_DIR/"

# Create a symlink to /Applications for drag-install
ln -s /Applications "$STAGING_DIR/Applications"

# Create the DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up staging
rm -rf "$STAGING_DIR"

echo ""
echo "==> DMG created: $DMG_PATH"
echo "    Size: $(du -h "$DMG_PATH" | cut -f1)"
