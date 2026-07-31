#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p Resources build

if [ -f Resources/AppIconSource.png ]; then
  SRC=Resources/AppIconSource.png
  echo "Icon-Quelle: $SRC (eigenes Artwork)"
else
  SRC=build/icon_512.png
  swift scripts/icon.swift "$SRC"
  echo "Icon-Quelle: $SRC (generiert)"
fi

ICONSET=build/AppIcon.iconset
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z "$s" "$s" "$SRC" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z "$d" "$d" "$SRC" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
echo "→ Resources/AppIcon.icns"
