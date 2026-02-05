#!/usr/bin/env bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change to the script's directory
cd "$SCRIPT_DIR" || exit 1

nvfetcher || exit 1

# Path to the extensions JSON file (relative to script directory, then to project root)
EXTENSIONS_JSON_FILE="../../home/features/vscode/marketplace-extensions.json"

# Generate JSON file from nvfetcher output
# Extract extensions with passthru (VS Code marketplace extensions) and convert to JSON array
jq '[.[] | select(.passthru != null) | {
  name: .passthru.name,
  publisher: .passthru.publisher,
  sha256: .src.sha256,
  version: .version
}]' _sources/generated.json > "$EXTENSIONS_JSON_FILE"

echo "Generated $EXTENSIONS_JSON_FILE"
echo ""
echo "Extensions updated. Review the file and rebuild your NixOS configuration."

# Also keep the old format for reference (optional)
result=$(jq '.[] | select(.passthru != null) | {name: .passthru.name, publisher: .passthru.publisher, sha256: .src.sha256, version: .version}' _sources/generated.json)
formatted_result=$(echo "$result" | sed -e 's/"name"/name/' -e 's/"publisher"/publisher/' -e 's/"sha256"/sha256/' -e 's/"version"/version/' -e 's/: / = /g' -e 's/,/;/g')
formatted_result=$(echo "$formatted_result" | sed -e 's/\([^;]\)"$/\1";/')
echo "$formatted_result" > generated-vscode-nix.txt

