#!/usr/bin/env bash
# Builds keepAwake.app into ./build.
#   --universal  build for Apple Silicon and Intel (used by release.sh)
#   --install    copy the app to /Applications and launch it
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

UNIVERSAL=false
INSTALL=false
for arg in "$@"; do
    case "$arg" in
        --universal) UNIVERSAL=true ;;
        --install) INSTALL=true ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

if $UNIVERSAL; then
    # SwiftPM's multi-arch flag needs full Xcode, so build each slice and merge them.
    slices=()
    for arch in arm64 x86_64; do
        triple="${arch}-apple-macosx${MIN_MACOS}"
        swift build -c release --triple "$triple"
        slices+=("$(swift build -c release --triple "$triple" --show-bin-path)/$EXECUTABLE")
    done
    lipo -create "${slices[@]}" -output "$APP_DIR/Contents/MacOS/$EXECUTABLE"
else
    swift build -c release
    cp "$(swift build -c release --show-bin-path)/$EXECUTABLE" "$APP_DIR/Contents/MacOS/$EXECUTABLE"
fi
cp Resources/AppIcon.icns Resources/PrivacyInfo.xcprivacy Resources/lid-sleep-helper.sh "$APP_DIR/Contents/Resources/"
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

# Ad-hoc signature without the App Sandbox: the lid-closed mode runs sudo and
# osascript, which the sandbox blocks. App Store builds use the Xcode project.
codesign --force --sign - "$APP_DIR"

echo "Built $APP_DIR ($VERSION, build $BUILD_NUMBER, $(lipo -archs "$APP_DIR/Contents/MacOS/$EXECUTABLE"))"

if $INSTALL; then
    pkill -x "$EXECUTABLE" 2>/dev/null || true
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" /Applications/
    echo "Installed /Applications/${APP_NAME}.app"
    open "/Applications/${APP_NAME}.app"
fi
