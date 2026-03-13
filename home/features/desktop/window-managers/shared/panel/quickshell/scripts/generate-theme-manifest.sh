#!/usr/bin/env bash
# Converts all base24 YAML theme files into a single JSON manifest for quickshell.
# Usage: generate-theme-manifest.sh <yaml-dir> <output-file>

set -euo pipefail

YAML_DIR="${1:?Usage: generate-theme-manifest.sh <yaml-dir> <output-file>}"
OUTPUT="${2:?Usage: generate-theme-manifest.sh <yaml-dir> <output-file>}"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

count=0
for f in "$YAML_DIR"/*.yaml; do
  [ -f "$f" ] || continue
  id="$(basename "$f" .yaml)"

  yq -o=json '.' "$f" | jq --arg id "$id" '{
    id: $id,
    name: .name,
    author: (.author // ""),
    variant: (.variant // "dark"),
    palette: .palette
  }' > "$tmpdir/$id.json"

  count=$((count + 1))
done

# Merge all individual theme JSONs into a single sorted array in one pass
jq -S -n '[inputs]' "$tmpdir"/*.json > "$OUTPUT"

echo "Generated manifest with $count themes → $OUTPUT"
