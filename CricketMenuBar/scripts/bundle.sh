#!/usr/bin/env bash
# Wrap the SPM-built executable into a proper macOS .app bundle so that
# LaunchServices can route the Google OAuth callback URL scheme back to us.
set -euo pipefail

CONFIG="${CONFIG:-debug}"
BUNDLE_ID="com.celeroncoder.CricketMenuBarLive"
APP_NAME="CricketMenuBar"
REVERSED_CLIENT_ID="com.googleusercontent.apps.298147131201-hjimmps69au2jcle02ctg4vogfpkutqp"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ Building ($CONFIG)…"
if [ "$CONFIG" = "release" ]; then
    swift build -c release
else
    swift build
fi

BIN_PATH="$ROOT/.build/$CONFIG/$APP_NAME"
if [ ! -x "$BIN_PATH" ]; then
    echo "✗ Binary not found at $BIN_PATH" >&2
    exit 1
fi

APP_DIR="$ROOT/.build/$CONFIG/$APP_NAME.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"

echo "▶ Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"

# Copy SPM-bundled resources (GoogleService-Info.plist, etc.) into Resources
# so FirebaseApp.configure() can find them at the standard location.
BUNDLE_RES="$ROOT/.build/$CONFIG/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$BUNDLE_RES" ]; then
    cp -R "$BUNDLE_RES" "$RES_DIR/"
fi
if [ -f "$ROOT/Sources/$APP_NAME/Resources/GoogleService-Info.plist" ]; then
    cp "$ROOT/Sources/$APP_NAME/Resources/GoogleService-Info.plist" "$RES_DIR/"
fi

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Cricket Menu Bar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>$BUNDLE_ID</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>$REVERSED_CLIENT_ID</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Strip quarantine attrs (e.g. from GoogleService-Info.plist downloaded via browser)
# — Gatekeeper rejects bundles containing quarantined files.
xattr -rd com.apple.quarantine "$APP_DIR" 2>/dev/null || true

# Ad-hoc codesign so the binary has a stable code identity. This is required
# for Firebase Auth's Keychain access to work — an unsigned binary has no
# identity, so the Keychain refuses to store/retrieve items for it.
# We intentionally do NOT add keychain-access-groups or other restricted
# entitlements — those require a provisioning profile and cause launchd to
# refuse spawning (POSIX 163) on ad-hoc signed apps.
echo "▶ Ad-hoc codesigning…"
codesign --force --sign - "$MACOS_DIR/$APP_NAME"
codesign --force --sign - "$APP_DIR"

# Register with LaunchServices so the URL scheme handler is known.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$APP_DIR" >/dev/null 2>&1 || true

echo "✓ Built $APP_DIR"

if [ "${1:-}" = "--run" ]; then
    echo "▶ Launching…"
    open "$APP_DIR"
fi
