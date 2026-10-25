#!/usr/bin/env bash
# Builds keepAwake.app into ./build. Pass --install to copy it to /Applications.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="keepAwake"
APP_DIR="build/${APP_NAME}.app"

# Native arch only: universal builds need full Xcode (xcbuild).
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/KeepAwake" "$APP_DIR/Contents/MacOS/KeepAwake"
cp Resources/Info.plist "$APP_DIR/Contents/Info.plist"

# Ad-hoc signature: enough to run locally and to register as a login item.
codesign --force --sign - "$APP_DIR"

echo "Built $APP_DIR"

if [[ "${1:-}" == "--install" ]]; then
    pkill -x KeepAwake 2>/dev/null || true
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" /Applications/
    echo "Installed /Applications/${APP_NAME}.app"
    open "/Applications/${APP_NAME}.app"
fi
