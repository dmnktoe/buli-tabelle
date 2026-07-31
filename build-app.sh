#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(grep 'static let version' Sources/BuLiTabelle/Version.swift | sed -E 's/.*"([^"]+)".*/\1/')
BUILD="${BULI_BUILD:-$(git rev-list --count HEAD 2>/dev/null || grep 'static let build' Sources/BuLiTabelle/Version.swift | sed -E 's/.*"([^"]+)".*/\1/')}"

SU_FEED_URL="${SU_FEED_URL:-https://dmnktoe.github.io/buli-tabelle/appcast.xml}"
SU_PUBLIC_ED_KEY="${SU_PUBLIC_ED_KEY:-gxNmaeCPi8fURiL6/sV9o66NstNRtjk9b2SIv2PiO94=}"

SIGN_IDENTITY="${SIGN_IDENTITY:-}"

APP=build/BuLiTabelle.app
FW_SRC=".build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"

echo "▸ BuLi Tabelle $VERSION (Build $BUILD)"
ARCHS=(--arch arm64 --arch x86_64)
swift build -c release "${ARCHS[@]}"
BIN_PATH=$(swift build -c release "${ARCHS[@]}" --show-bin-path)

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN_PATH/BuLiTabelle" "$APP/Contents/MacOS/BuLiTabelle"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>BuLi Tabelle</string>
    <key>CFBundleDisplayName</key><string>BuLi Tabelle</string>
    <key>CFBundleIdentifier</key><string>de.dmnktoe.bulitabelle</string>
    <key>CFBundleExecutable</key><string>BuLiTabelle</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD}</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.sports</string>
    <key>SUFeedURL</key><string>${SU_FEED_URL}</string>
    <key>SUPublicEDKey</key><string>${SU_PUBLIC_ED_KEY}</string>
    <key>SUEnableAutomaticChecks</key><true/>
</dict>
</plist>
EOF

if [ ! -f Resources/AppIcon.icns ]; then
  bash scripts/make-icon.sh || echo "Hinweis: Icon konnte nicht erzeugt werden."
fi
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"

if [ ! -d "$FW_SRC" ]; then
  echo "Sparkle nicht gefunden – löse Abhängigkeit auf…"; swift package resolve
fi
ditto "$FW_SRC" "$APP/Contents/Frameworks/Sparkle.framework"

install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/BuLiTabelle" 2>/dev/null || true

FW="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
if [ -n "$SIGN_IDENTITY" ]; then
  RUNTIME=(--options runtime --timestamp)
  echo "▸ Signiere mit: $SIGN_IDENTITY (Hardened Runtime)"
else
  SIGN_IDENTITY="-"
  RUNTIME=()
  echo "▸ Signiere ad-hoc (nur lokaler Test, nicht verteilbar)"
fi

sign() { codesign --force ${RUNTIME[@]+"${RUNTIME[@]}"} --preserve-metadata=entitlements -s "$SIGN_IDENTITY" "$1"; }

for x in "$FW/XPCServices/Downloader.xpc" "$FW/XPCServices/Installer.xpc" \
         "$FW/Autoupdate" "$FW/Updater.app"; do
  [ -e "$x" ] && sign "$x"
done
codesign --force ${RUNTIME[@]+"${RUNTIME[@]}"} -s "$SIGN_IDENTITY" "$APP/Contents/Frameworks/Sparkle.framework"

codesign --force ${RUNTIME[@]+"${RUNTIME[@]}"} --entitlements BuLiTabelle.entitlements -s "$SIGN_IDENTITY" "$APP"

echo "▸ Prüfe Signatur…"
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | tail -3 || true

echo "→ $APP  (starten mit: open $APP)"
