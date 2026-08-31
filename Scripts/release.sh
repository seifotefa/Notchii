#!/usr/bin/env bash
# Builds a universal Notchii.app, wraps it in a DMG, and — if you have
# credentials — signs, notarizes and staples it.
#
# Without credentials it still produces a working (unsigned) DMG, so the
# whole pipeline is testable before you have an Apple Developer account.
#
#   DEVELOPER_ID      "Developer ID Application: Your Name (TEAMID)"
#   NOTARY_PROFILE    notarytool keychain profile name
#
# Store the notary profile once with:
#   xcrun notarytool store-credentials <profile> --apple-id <id> \
#     --team-id <TEAMID> --password <app-specific-password>
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="Notchii"
DIST="$ROOT/dist"
APP="$DIST/$NAME.app"
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$ROOT/dist/$NAME.app/Contents/Info.plist" 2>/dev/null || echo 0.1.0)}"
DMG="$DIST/$NAME-$VERSION.dmg"

echo "==> Building $NAME $VERSION (universal)"
rm -rf "$DIST"
mkdir -p "$DIST"
swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT"
BIN="$(swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT" --show-bin-path)/$NAME"

echo "==> Assembling $NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$NAME</string>
    <key>CFBundleDisplayName</key><string>$NAME</string>
    <key>CFBundleExecutable</key><string>$NAME</string>
    <key>CFBundleIdentifier</key><string>com.notchii.app</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Notchii uses Apple Events to read what is playing in Spotify and Apple Music and to control playback.</string>
</dict>
</plist>
PLIST

if [[ -n "${DEVELOPER_ID:-}" ]]; then
    echo "==> Signing with Developer ID"
    # Hardened runtime is required for notarization.
    codesign --force --timestamp --options runtime \
        --sign "$DEVELOPER_ID" "$APP"
else
    echo "==> No DEVELOPER_ID set; ad-hoc signing (Gatekeeper will block downloads)"
    codesign --force --sign - "$APP"
fi

echo "==> Building DMG"
STAGING="$(mktemp -d)"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create \
    -volname "$NAME" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDZO \
    -ov "$DMG" >/dev/null
rm -rf "$STAGING"

if [[ -n "${DEVELOPER_ID:-}" && -n "${NOTARY_PROFILE:-}" ]]; then
    echo "==> Signing and notarizing DMG (this takes a few minutes)"
    codesign --force --timestamp --sign "$DEVELOPER_ID" "$DMG"
    xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG"
    echo "==> Notarized and stapled"
else
    echo "==> Skipping notarization (set DEVELOPER_ID and NOTARY_PROFILE to enable)"
fi

# A copy at a fixed name, so the landing page can link to one permanent URL.
cp "$DMG" "$DIST/$NAME.dmg"

SHA="$(shasum -a 256 "$DMG" | cut -d' ' -f1)"
cat > "$DIST/latest.json" <<JSON
{
  "version": "$VERSION",
  "date": "$(date -u +%Y-%m-%d)",
  "url": "https://github.com/OWNER/Notchii/releases/latest/download/$NAME.dmg",
  "sha256": "$SHA",
  "minimumSystemVersion": "13.0"
}
JSON

echo
echo "Built:  $DMG"
echo "Latest: $DIST/$NAME.dmg"
echo "SHA256: $SHA"
lipo -archs "$APP/Contents/MacOS/$NAME"
