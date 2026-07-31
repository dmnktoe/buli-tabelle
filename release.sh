#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(grep 'static let version' Sources/BuLiTabelle/Version.swift | sed -E 's/.*"([^"]+)".*/\1/')
GH_REPO="${GH_REPO:-dmnktoe/buli-tabelle}"
FEED_URL="${SU_FEED_URL:-https://dmnktoe.github.io/buli-tabelle/appcast.xml}"
export BULI_BUILD="${BULI_BUILD:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"

echo "▸ Baue BuLi Tabelle $VERSION (Build $BULI_BUILD)…"
./build-app.sh

if [ -z "${SIGN_IDENTITY:-}" ]; then
  echo "⚠️  SIGN_IDENTITY nicht gesetzt → App nur ad-hoc signiert und wird auf"
  echo "    fremden Macs von Gatekeeper blockiert. Für echte Verteilung Developer ID setzen."
fi

./scripts/notarize.sh "build/BuLi Tabelle.app"
GH_REPO="$GH_REPO" ./scripts/make-appcast.sh

echo ""
echo "Nächste Schritte (nur bei rein lokalem Release nötig):"
echo "  1. GitHub-Release 'v$VERSION' anlegen und dist/BuLiTabelle-$VERSION.zip als Asset hochladen."
echo "  2. docs/appcast.xml committen & pushen → wird unter"
echo "     $FEED_URL ausgeliefert (GitHub Pages)."
echo "  Tipp: Normalerweise reicht ein Push auf main mit neuer Version in"
echo "  Version.swift — die CI baut, taggt und veröffentlicht dann automatisch."
