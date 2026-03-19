#!/usr/bin/env bash
# Searches the cached DDG bang database for matching bangs.
# Usage: qs-bang-search <prefix>
# Output: JSON array of top 10 matches [{t, s, u}, ...]

set -euo pipefail

PREFIX="${1:-}"
DB="${HOME}/.local/state/quickshell/ddg-bangs.json"

if [ -z "${PREFIX}" ]; then
    echo "[]"
    exit 0
fi

if [ ! -f "${DB}" ]; then
    echo "[]"
    exit 0
fi

jq -c --arg p "${PREFIX}" \
    '[.[] | select(.t | startswith($p))] | .[0:10]' \
    < "${DB}"
