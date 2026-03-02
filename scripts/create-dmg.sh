#!/usr/bin/env bash
# Create a DMG for ClipboardManager.app for distribution.
# Usage: ./scripts/create-dmg.sh [path/to/ClipboardManager.app]
#   If no path is given, uses build/Build/Products/Release/ClipboardManager.app
#   if it exists (e.g. after ./scripts/build-and-install.sh or a Release build).
# Output: ClipboardManager-<version>.dmg in the project root.
# Users double-click the DMG and drag the app to Applications.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="ClipboardManager.app"
VOLUME_NAME="Clipboard Manager"

if [[ -n "$1" ]]; then
  SOURCE_APP="$1"
else
  SOURCE_APP="$PROJECT_ROOT/build/Build/Products/Release/$APP_NAME"
fi

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Error: App not found at $SOURCE_APP" >&2
  echo "Usage: $0 [path/to/ClipboardManager.app]" >&2
  echo "  Build first with: ./scripts/build-and-install.sh" >&2
  echo "  Or pass the path to an exported .app (e.g. from Xcode Archive)." >&2
  exit 1
fi

# Read version from the app's Info.plist
VERSION="$(defaults read "$SOURCE_APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0")"
DMG_NAME="ClipboardManager-${VERSION}.dmg"
DMG_PATH="$PROJECT_ROOT/$DMG_NAME"
STAGING_DIR="$(mktemp -d -t clipboardmanager-dmg)"
trap 'rm -rf "$STAGING_DIR"' EXIT

echo "Creating DMG for $APP_NAME (version $VERSION)..."

cp -R "$SOURCE_APP" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Size: content size + ~20 MB for filesystem and padding
SIZE_MB=$(du -sm "$STAGING_DIR" | cut -f1)
SIZE_MB=$((SIZE_MB + 20))

DMG_TMP="${STAGING_DIR}-tmp.dmg"

hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
  -format UDRW -size "${SIZE_MB}m" "$DMG_TMP" -quiet

hdiutil convert "$DMG_TMP" -format UDZO -o "$DMG_PATH" -quiet
rm -f "$DMG_TMP"

echo "Created: $DMG_PATH"
echo "Users can double-click the DMG and drag the app to Applications."
