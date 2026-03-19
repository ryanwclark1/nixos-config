#!/usr/bin/env bash
# Downloads the DuckDuckGo bang database and indexes it into a compact JSON file.
# Output: ~/.local/state/quickshell/ddg-bangs.json

set -euo pipefail

STATE_DIR="${HOME}/.local/state/quickshell"
OUTPUT="${STATE_DIR}/ddg-bangs.json"
TEMP="${OUTPUT}.tmp"

mkdir -p "${STATE_DIR}"

echo "Downloading DDG bang database..." >&2
curl -sL "https://duckduckgo.com/bang.js" -o "${TEMP}.raw"

echo "Indexing bangs..." >&2
jq -c '[.[] | {t: .t, s: .s, u: .u}]' < "${TEMP}.raw" > "${TEMP}"
rm -f "${TEMP}.raw"
mv "${TEMP}" "${OUTPUT}"

COUNT=$(jq 'length' < "${OUTPUT}")
echo "Synced ${COUNT} bangs to ${OUTPUT}" >&2
