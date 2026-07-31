#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP="${1:-build/BuLi Tabelle.app}"
[ -d "$APP" ] || { echo "✗ $APP fehlt — erst ./build-app.sh ausführen."; exit 1; }

NOTARY_ARGS=()
if [ -n "${NOTARY_PROFILE:-}" ]; then
  NOTARY_ARGS=(--keychain-profile "$NOTARY_PROFILE")
  echo "▸ Notarisierung via Keychain-Profil '$NOTARY_PROFILE'."
elif [ -n "${NOTARY_KEY_FILE:-}" ] && [ -n "${NOTARY_KEY_ID:-}" ] && [ -n "${NOTARY_ISSUER:-}" ]; then
  NOTARY_ARGS=(--key "$NOTARY_KEY_FILE" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER")
  echo "▸ Notarisierung via App-Store-Connect-API-Key."
elif [ -n "${NOTARY_APPLE_ID:-}" ] && [ -n "${NOTARY_PASSWORD:-}" ] && [ -n "${NOTARY_TEAM_ID:-}" ]; then
  NOTARY_ARGS=(--apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$NOTARY_TEAM_ID")
  echo "▸ Notarisierung via Apple-ID."
else
  echo "▸ Keine Notarisierungs-Credentials gesetzt → überspringe Notarisierung."
  exit 0
fi

TMP="$(mktemp -d)"
ZIP="$TMP/BuLiTabelle-notarize.zip"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "▸ Reiche zur Notarisierung ein (kann einige Minuten dauern)…"
xcrun notarytool submit "$ZIP" "${NOTARY_ARGS[@]}" --wait

echo "▸ Tacker das Ticket an die App…"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
echo "✓ Notarisiert & getackert: $APP"
