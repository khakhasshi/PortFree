#!/bin/zsh
set -euo pipefail

# PortFree Build & Package Script
# Usage: ./build.sh [--skip-archive]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SCHEME="PortFree"
CONFIG="Release"
BUILD_DIR="build"
ARCHIVE_PATH="$BUILD_DIR/PortFree.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
DMG_STAGING="$BUILD_DIR/dmg-staging"
VERSION=$(grep -m1 'MARKETING_VERSION' PortFree.xcodeproj/project.pbxproj | tr -d ' ;' | cut -d= -f2)
DMG_NAME="PortFree-v${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
SIGN_ID="Developer ID Application: JINGZHE JIANG (3PS7QR8L7W)"
WIDGET_ENTITLEMENTS="PortFreeWidget/PortFreeWidget.entitlements"
APP_ENTITLEMENTS="PortFree/PortFree.entitlements"

echo "=== PortFree Build Script ==="
echo "Version: $VERSION"
echo ""

# --- 1. Clean ---
echo "[1/6] Cleaning..."
rm -rf "$EXPORT_DIR" "$DMG_STAGING" "$DMG_PATH"

# --- 2. Archive ---
if [[ "${1:-}" == "--skip-archive" && -d "$ARCHIVE_PATH" ]]; then
    echo "[2/6] Skipping archive (using existing)"
else
    echo "[2/6] Archiving..."
    rm -rf "$ARCHIVE_PATH"
    xcodebuild archive \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -archivePath "$ARCHIVE_PATH" \
        2>&1 | tail -3
fi

# --- 3. Export from archive ---
echo "[3/6] Exporting app from archive..."
mkdir -p "$EXPORT_DIR"
cp -R "$ARCHIVE_PATH/Products/Applications/PortFree.app" "$EXPORT_DIR/"

# --- 4. Code sign (widget first, then main app) ---
echo "[4/6] Signing..."
# Widget extension (sandboxed, with entitlements)
codesign --force --sign "$SIGN_ID" \
    --options runtime \
    --entitlements "$WIDGET_ENTITLEMENTS" \
    "$EXPORT_DIR/PortFree.app/Contents/PlugIns/PortFreeWidgetExtension.appex"

# Main app (with entitlements, no --deep)
codesign --force --sign "$SIGN_ID" \
    --options runtime \
    --entitlements "$APP_ENTITLEMENTS" \
    "$EXPORT_DIR/PortFree.app"

# Verify
codesign --verify --deep --strict "$EXPORT_DIR/PortFree.app"
echo "  ✓ Signature verified"

# --- 5. Create DMG ---
echo "[5/6] Creating DMG..."
mkdir -p "$DMG_STAGING"
cp -R "$EXPORT_DIR/PortFree.app" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "PortFree" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" > /dev/null 2>&1
codesign --force --sign "$SIGN_ID" "$DMG_PATH"
echo "  ✓ DMG created"

# --- 6. Summary ---
echo "[6/6] Done!"
echo ""
echo "  DMG: $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1 | tr -d ' '))"
echo ""
echo "  Quick install: cp -R $EXPORT_DIR/PortFree.app /Applications/"
echo "  Open DMG:      open $DMG_PATH"
