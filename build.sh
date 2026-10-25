#!/usr/bin/env bash
# Builds keepAwake.app into ./build. Pass --install to copy it to /Applications.
# For App Store builds use the Xcode project instead (see APPSTORE.md).
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="keepAwake"
APP_DIR="build/${APP_NAME}.app"
EXECUTABLE="KeepAwake"
BUNDLE_ID="com.michalkrecisz.keepAwake"
MIN_MACOS="14.0"
VERSION="$(sed -n 's/^ *MARKETING_VERSION: *//p' project.yml)"
BUILD_NUMBER="$(sed -n 's/^ *CURRENT_PROJECT_VERSION: *//p' project.yml)"

# Native arch only: universal builds need full Xcode (xcbuild).
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/$EXECUTABLE" "$APP_DIR/Contents/MacOS/$EXECUTABLE"
cp Resources/AppIcon.icns Resources/PrivacyInfo.xcprivacy "$APP_DIR/Contents/Resources/"
# SwiftPM does not compile the asset catalog: ship the menu bar images as loose PNGs,
# which NSImage(named:) finds the same way.
cp Resources/Assets.xcassets/MenuBarIcon*.imageset/*.png "$APP_DIR/Contents/Resources/"

# Fill in the Xcode build variables used in Info.plist.
sed -e "s/\$(EXECUTABLE_NAME)/$EXECUTABLE/" \
    -e "s/\$(PRODUCT_BUNDLE_IDENTIFIER)/$BUNDLE_ID/" \
    -e "s/\$(MARKETING_VERSION)/$VERSION/" \
    -e "s/\$(CURRENT_PROJECT_VERSION)/$BUILD_NUMBER/" \
    -e "s/\$(MACOSX_DEPLOYMENT_TARGET)/$MIN_MACOS/" \
    Resources/Info.plist > "$APP_DIR/Contents/Info.plist"

# Ad-hoc signature with the App Store sandbox entitlements, so local builds
# behave like the store version.
codesign --force --sign - --entitlements Resources/keepAwake.entitlements "$APP_DIR"

echo "Built $APP_DIR ($VERSION, build $BUILD_NUMBER)"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x "$EXECUTABLE" 2>/dev/null || true
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" /Applications/
    echo "Installed /Applications/${APP_NAME}.app"
    open "/Applications/${APP_NAME}.app"
fi
