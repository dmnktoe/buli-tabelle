#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(grep 'static let version' Sources/BuLiTabelle/Version.swift | sed -E 's/.*"([^"]+)".*/\1/')
APP="build/BuLi Tabelle.app"
DIST="dist"
GH_REPO="${GH_REPO:-dmnktoe/buli-tabelle}"
DOWNLOAD_PREFIX="https://github.com/${GH_REPO}/releases/download/v${VERSION}/"
APPCAST="${APPCAST:-docs/appcast.xml}"

[ -d "$APP" ] || { echo "✗ $APP fehlt — erst ./build-app.sh ausführen."; exit 1; }

BIN=".build/artifacts/sparkle/Sparkle/bin"
if [ ! -x "$BIN/generate_appcast" ]; then
  FOUND=$(find .build -type f -name generate_appcast -path '*Sparkle*' 2>/dev/null | head -n1 || true)
  [ -n "$FOUND" ] && BIN=$(dirname "$FOUND")
fi
[ -x "$BIN/generate_appcast" ] || { echo "✗ generate_appcast nicht gefunden — 'swift build' ausführen."; exit 1; }

mkdir -p "$DIST"
ZIP="$DIST/BuLiTabelle-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
echo "→ $ZIP ($(du -h "$ZIP" | cut -f1))"

GENDIR="$(mktemp -d)"
cp "$ZIP" "$GENDIR/"

ED_ARGS=()
if [ -n "${SPARKLE_ED_KEY_FILE:-}" ]; then
  ED_ARGS=(--ed-key-file "$SPARKLE_ED_KEY_FILE")
  echo "▸ Signiere Appcast mit EdDSA-Key-Datei ($SPARKLE_ED_KEY_FILE)."
else
  echo "▸ Signiere Appcast mit EdDSA-Key aus der Keychain."
fi

"$BIN/generate_appcast" ${ED_ARGS[@]+"${ED_ARGS[@]}"} \
  --download-url-prefix "$DOWNLOAD_PREFIX" "$GENDIR"

NOTES_ARGS=()
if [ -n "${APPCAST_NOTES_HTML:-}" ] && [ -s "${APPCAST_NOTES_HTML:-/nonexistent}" ]; then
  NOTES_ARGS=(--notes-html "$APPCAST_NOTES_HTML")
  echo "▸ Betten Release-Notes aus $APPCAST_NOTES_HTML ein."
fi

python3 scripts/merge-appcast.py \
  --current "$APPCAST" --new "$GENDIR/appcast.xml" --out "$APPCAST" --title "BuLi Tabelle" \
  ${NOTES_ARGS[@]+"${NOTES_ARGS[@]}"}

echo "→ $APPCAST aktualisiert (v$VERSION)"
