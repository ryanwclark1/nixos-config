#!/usr/bin/env bash
set -euo pipefail

# Path to the info.json file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFO_JSON_PATH="$SCRIPT_DIR/../../pkgs/windsurf/info.json"

# Function to get latest info for a target system
get_info() {
  local target_system="$1"
  local url="https://windsurf-stable.codeiumdata.com/api/update/${target_system}/stable/latest"

  # Fetch the latest info and store it
  echo "Fetching from: $url"
  local response=$(curl -s "$url")

  # Debug: Print the response
  echo "Response: $response"

  # Check if response is valid JSON
  if ! echo "$response" | jq . >/dev/null 2>&1; then
    echo "Error: Invalid JSON response from API"
    echo "Response was: $response"
    return 1
  fi

  # Check if we need to scrape the downloads page instead
  # Try alternative approach - get latest version from the website
  echo "Attempting to get latest version info from alternative source..."

  # Try to find the latest versions and build IDs
  if [ "$target_system" = "darwin-arm64" ]; then
    platform_path="darwin/arm64"
    platform_suffix="arm64"
  elif [ "$target_system" = "darwin-x64" ]; then
    platform_path="darwin/x64"
    platform_suffix="x64"
  elif [ "$target_system" = "linux-x64" ]; then
    platform_path="linux/x64"
    platform_suffix="x86_64"
  else
    echo "Unknown platform: $target_system"
    return 1
  fi

  # Get the latest version info from latest-versions.json (similar to the Cursor approach)
  local versions_json=$(curl -s "https://download.windsurf.app/latest-versions.json" || curl -s "https://windsurf-stable.codeiumdata.com/latest-versions.json")

  if [ -z "$versions_json" ]; then
    echo "Failed to fetch versions data"
    return 1
  fi

  echo "Versions data: $versions_json"

  # Extract version and build ID (structure might need adjustment based on actual JSON)
  local version=$(echo "$versions_json" | jq -r '.latestVers.main.ver // .version // "1.6.0"')
  local build_id=$(echo "$versions_json" | jq -r '.latestVers.main.buildId // .buildId // ""')

  if [ -z "$version" ] || [ "$version" = "null" ]; then
    echo "Could not determine version"
    version="1.6.0" # Use a fallback version
  fi

  # If we can't get build_id from JSON, try to find it through download links
  if [ -z "$build_id" ] || [ "$build_id" = "null" ]; then
    echo "Build ID not found, using static URL patterns"

    # Try to construct URL based on known patterns
    local download_url="https://windsurf-stable.codeiumdata.com/${platform_path}/stable/latest/Windsurf-${target_system}-${version}.zip"
    if [ "$target_system" = "linux-x64" ]; then
      download_url="https://windsurf-stable.codeiumdata.com/${platform_path}/stable/latest/Windsurf-${target_system}-${version}.tar.gz"
    fi
  else
    # Construct URL with build ID
    local download_url="https://windsurf-stable.codeiumdata.com/${platform_path}/stable/${build_id}/Windsurf-${target_system}-${version}.zip"
    if [ "$target_system" = "linux-x64" ]; then
      download_url="https://windsurf-stable.codeiumdata.com/${platform_path}/stable/${build_id}/Windsurf-${target_system}-${version}.tar.gz"
    fi
  fi

  echo "Constructed URL: $download_url"

  # Get the sha256 by downloading and hashing
  echo "Calculating SHA256 hash (this might take a while)..."
  local sha256hash=""
  if command -v nix-prefetch-url &> /dev/null; then
    sha256hash=$(nix-prefetch-url "$download_url" 2>/dev/null || echo "")
  fi

  if [ -z "$sha256hash" ]; then
    echo "Could not calculate SHA256, using placeholder (update manually)"
    sha256hash="0000000000000000000000000000000000000000000000000000000000000000"
  fi

  # VS Code version - often similar to or incrementally higher than Windsurf version
  local vscode_version="1.94.0"  # Fallback

  # Return the formatted JSON
  echo "{\"version\":\"$version\",\"vscodeVersion\":\"$vscode_version\",\"url\":\"$download_url\",\"sha256\":\"$sha256hash\"}"
}

# Function to update the info.json file
update_info_json() {
  # Check if info.json file exists
  if [ ! -f "$INFO_JSON_PATH" ]; then
    echo "Error: info.json file not found at $INFO_JSON_PATH"
    exit 1
  fi

  echo "Reading existing info.json..."
  # Read the old JSON file
  local old_info=$(cat "$INFO_JSON_PATH")

  echo "Fetching info for aarch64-darwin..."
  local aarch64_darwin_info=""
  aarch64_darwin_info=$(get_info "darwin-arm64") || {
    echo "Warning: Failed to get aarch64-darwin info, keeping old values"
    aarch64_darwin_info=$(echo "$old_info" | jq -r '.["aarch64-darwin"]')
  }

  echo "Fetching info for x86_64-darwin..."
  local x86_64_darwin_info=""
  x86_64_darwin_info=$(get_info "darwin-x64") || {
    echo "Warning: Failed to get x86_64-darwin info, keeping old values"
    x86_64_darwin_info=$(echo "$old_info" | jq -r '.["x86_64-darwin"]')
  }

  echo "Fetching info for x86_64-linux..."
  local x86_64_linux_info=""
  x86_64_linux_info=$(get_info "linux-x64") || {
    echo "Warning: Failed to get x86_64-linux info, keeping old values"
    x86_64_linux_info=$(echo "$old_info" | jq -r '.["x86_64-linux"]')
  }

  # Create the new JSON structure
  local new_info=$(cat <<EOF
{
  "aarch64-darwin": $aarch64_darwin_info,
  "x86_64-darwin": $x86_64_darwin_info,
  "x86_64-linux": $x86_64_linux_info
}
EOF
)

  # Compare versions
  local old_aarch64_darwin_version=$(echo "$old_info" | jq -r '."aarch64-darwin".version')
  local new_aarch64_darwin_version=$(echo "$aarch64_darwin_info" | jq -r '.version')

  local old_x86_64_darwin_version=$(echo "$old_info" | jq -r '."x86_64-darwin".version')
  local new_x86_64_darwin_version=$(echo "$x86_64_darwin_info" | jq -r '.version')

  local old_x86_64_linux_version=$(echo "$old_info" | jq -r '."x86_64-linux".version')
  local new_x86_64_linux_version=$(echo "$x86_64_linux_info" | jq -r '.version')

  echo "Version comparison:"
  echo "aarch64-darwin: $old_aarch64_darwin_version -> $new_aarch64_darwin_version"
  echo "x86_64-darwin: $old_x86_64_darwin_version -> $new_x86_64_darwin_version"
  echo "x86_64-linux: $old_x86_64_linux_version -> $new_x86_64_linux_version"

  # Determine if there's an update
  if [ "$old_aarch64_darwin_version" = "$new_aarch64_darwin_version" ] && \
     [ "$old_x86_64_darwin_version" = "$new_x86_64_darwin_version" ] && \
     [ "$old_x86_64_linux_version" = "$new_x86_64_linux_version" ]; then
    echo "[update] No version changes found"
    return 0
  fi

  # Log the updates
  [ "$old_aarch64_darwin_version" != "$new_aarch64_darwin_version" ] && \
    echo "[update] Updating Windsurf aarch64-darwin $old_aarch64_darwin_version -> $new_aarch64_darwin_version"

  [ "$old_x86_64_darwin_version" != "$new_x86_64_darwin_version" ] && \
    echo "[update] Updating Windsurf x86_64-darwin $old_x86_64_darwin_version -> $new_x86_64_darwin_version"

  [ "$old_x86_64_linux_version" != "$new_x86_64_linux_version" ] && \
    echo "[update] Updating Windsurf x86_64-linux $old_x86_64_linux_version -> $new_x86_64_linux_version"

  # Write the new JSON to the file
  echo "$new_info" > "$INFO_JSON_PATH"
  echo "[update] Updating Windsurf complete"
  echo "[update] NOTE: Please verify SHA256 hashes - they may need manual verification"
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
  fi

  # Update the info.json file
  update_info_json
}

# Execute the script
main
