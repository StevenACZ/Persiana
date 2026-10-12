#!/usr/bin/env bash
# Build Persiana.app and sign it with the local Apple Development identity.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/Persiana.app"
BUNDLE_ID="${PERSIANA_BUNDLE_ID:-com.stevenacz.Persiana}"
SIGN_IDENTITY="${SIGN_IDENTITY:-$(security find-identity -p codesigning -v | awk -F '"' '/Apple Development/ { print $2; exit }')}"

cd "$ROOT"
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Persiana "$APP/Contents/MacOS/Persiana"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Persiana</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleName</key><string>Persiana</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP"
codesign -dv "$APP" 2>&1 | grep -E "Identifier|Authority=" | head -3
