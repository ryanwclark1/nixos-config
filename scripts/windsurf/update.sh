#!/usr/bin/env bash
set -euo pipefail

# Path to the info.json file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFO_JSON_PATH="$SCRIPT_DIR/info.json"

# Function to get latest info for a target system
get_info() {
  local target_system="$1"
  local url="https://windsurf-stable.codeium.com/api/update/${target_system}/stable/latest"

  # Fetch the latest info
  local response=$(curl -s "$url")

  # Extract the required fields
  local windsurf_version=$(echo "$response" | jq -r '.windsurfVersion')
  local product_version=$(echo "$response" | jq -r '.productVersion')
  local download_url=$(echo "$response" | jq -r '.url')
  local sha256hash=$(echo "$response" | jq -r '.sha256hash')

  # Validate the fields
  [[ -n "$windsurf_version" && "$windsurf_version" != "null" ]] || { echo "Error: windsurfVersion is missing"; exit 1; }
  [[ -n "$product_version" && "$product_version" != "null" ]] || { echo "Error: productVersion is missing"; exit 1; }
  [[ -n "$download_url" && "$download_url" != "null" ]] || { echo "Error: url is missing"; exit 1; }
  [[ -n "$sha256hash" && "$sha256hash" != "null" ]] || { echo "Error: sha256hash is missing"; exit 1; }

  # Return the formatted JSON
  echo "{\"version\":\"$windsurf_version\",\"vscodeVersion\":\"$product_version\",\"url\":\"$download_url\",\"sha256\":\"$sha256hash\"}"
}

# Function to update the info.json file
update_info_json() {
  # Get information for each platform
  local aarch64_darwin_info=$(get_info "darwin-arm64")
  local x86_64_darwin_info=$(get_info "darwin-x64")
  local x86_64_linux_info=$(get_info "linux-x64")

  # Create the new JSON structure
  local new_info=$(cat <<EOF
{
  "aarch64-darwin": $aarch64_darwin_info,
  "x86_64-darwin": $x86_64_darwin_info,
  "x86_64-linux": $x86_64_linux_info
}
EOF
)

  # Read the old JSON file
  local old_info=$(cat "$INFO_JSON_PATH")

  # Compare the old and new JSON (normalized)
  if [ "$(echo "$old_info" | jq -S .)" = "$(echo "$new_info" | jq -S .)" ]; then
    echo "[update] No updates found"
    return 0
  fi

  # Log the updates
  local old_aarch64_darwin_version=$(echo "$old_info" | jq -r '."aarch64-darwin".version')
  local new_aarch64_darwin_version=$(echo "$aarch64_darwin_info" | jq -r '.version')
  echo "[update] Updating Windsurf aarch64-darwin $old_aarch64_darwin_version -> $new_aarch64_darwin_version"

  local old_x86_64_darwin_version=$(echo "$old_info" | jq -r '."x86_64-darwin".version')
  local new_x86_64_darwin_version=$(echo "$x86_64_darwin_info" | jq -r '.version')
  echo "[update] Updating Windsurf x86_64-darwin $old_x86_64_darwin_version -> $new_x86_64_darwin_version"

  local old_x86_64_linux_version=$(echo "$old_info" | jq -r '."x86_64-linux".version')
  local new_x86_64_linux_version=$(echo "$x86_64_linux_info" | jq -r '.version')
  echo "[update] Updating Windsurf x86_64-linux $old_x86_64_linux_version -> $new_x86_64_linux_version"

  # Write the new JSON to the file
  echo "$new_info" > "$INFO_JSON_PATH"
  echo "[update] Updating Windsurf complete"
}

# Main function
main() {
  # Ensure jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
  fi

  # Ensure curl is installed
  if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed."
    exit 1
  }

  # Update the info.json file
  update_info_json
}

# Execute the script
main
