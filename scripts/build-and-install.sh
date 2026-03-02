#!/usr/bin/env bash
# Build ClipboardManager in Release and copy the app to /Applications.
# Run from the project root (parent of ClipboardManager.xcodeproj).
# No code signing required for local use. First launch may trigger Gatekeeper;
# use right-click → Open once, or: xattr -cr /Applications/ClipboardManager.app

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="ClipboardManager"
SCHEME="ClipboardManager"
CONFIGURATION="Release"
BUILD_DIR="$PROJECT_ROOT/build"
APP_NAME="$PROJECT_NAME.app"
APPLICATIONS="/Applications"

cd "$PROJECT_ROOT"

if [[ ! -f "ClipboardManager.xcodeproj/project.pbxproj" ]]; then
  echo "Error: Run this script from the project root (where ClipboardManager.xcodeproj lives)." >&2
  exit 1
fi

echo "Building $PROJECT_NAME ($CONFIGURATION)..."
xcodebuild build \
  -project "ClipboardManager.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  -destination "platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO

SOURCE_APP="$BUILD_DIR/Build/Products/$CONFIGURATION/$APP_NAME"
if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Error: Build did not produce $SOURCE_APP" >&2
  exit 1
fi

DEST_APP="$APPLICATIONS/$APP_NAME"
if [[ -d "$DEST_APP" ]]; then
  echo "Removing existing $DEST_APP..."
  rm -rf "$DEST_APP"
fi

echo "Installing to $DEST_APP..."
cp -R "$SOURCE_APP" "$DEST_APP"

echo "Done. Launch with: open $DEST_APP"
echo "If Gatekeeper blocks it, right-click the app → Open once, or run: xattr -cr $DEST_APP"
