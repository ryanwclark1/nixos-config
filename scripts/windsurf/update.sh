#!/usr/bin/env bash
set -euo pipefail

# Path to the info.json file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFO_JSON_PATH="$SCRIPT_DIR/../../pkgs/windsurf/info.json"

# Function to fetch and extract information for a platform
fetch_platform_info() {
  local target_system="$1"
  local api_url="https://windsurf-stable.codeium.com/api/update/${target_system}/stable/latest"

  echo "Fetching from: $api_url"
  local response=$(curl -s "$api_url")

  # Extract the required information
  local windsurf_version=$(echo "$response" | jq -r '.windsurfVersion')
  local product_version=$(echo "$response" | jq -r '.productVersion')
  local download_url=$(echo "$response" | jq -r '.url')
  local sha256hash=$(echo "$response" | jq -r '.sha256hash')

  echo "Found version $windsurf_version for $target_system"

  # Store the platform information in variables
  if [ "$target_system" = "darwin-arm64" ]; then
    aarch64_darwin_version="$windsurf_version"
    aarch64_darwin_vscode_version="$product_version"
    aarch64_darwin_url="$download_url"
    aarch64_darwin_sha256="$sha256hash"
  elif [ "$target_system" = "darwin-x64" ]; then
    x86_64_darwin_version="$windsurf_version"
    x86_64_darwin_vscode_version="$product_version"
    x86_64_darwin_url="$download_url"
    x86_64_darwin_sha256="$sha256hash"
  elif [ "$target_system" = "linux-x64" ]; then
    x86_64_linux_version="$windsurf_version"
    x86_64_linux_vscode_version="$product_version"
    x86_64_linux_url="$download_url"
    x86_64_linux_sha256="$sha256hash"
  fi
}

# Main function to update info.json
update_info_json() {
  # Declare variables for platform information
  local aarch64_darwin_version=""
  local aarch64_darwin_vscode_version=""
  local aarch64_darwin_url=""
  local aarch64_darwin_sha256=""

  local x86_64_darwin_version=""
  local x86_64_darwin_vscode_version=""
  local x86_64_darwin_url=""
  local x86_64_darwin_sha256=""

  local x86_64_linux_version=""
  local x86_64_linux_vscode_version=""
  local x86_64_linux_url=""
  local x86_64_linux_sha256=""

  # Fetch information for each platform
  fetch_platform_info "darwin-arm64"
  fetch_platform_info "darwin-x64"
  fetch_platform_info "linux-x64"

  # Create the JSON content directly
  cat > "$INFO_JSON_PATH" << EOF
{
  "aarch64-darwin": {
    "version": "$aarch64_darwin_version",
    "vscodeVersion": "$aarch64_darwin_vscode_version",
    "url": "$aarch64_darwin_url",
    "sha256": "$aarch64_darwin_sha256"
  },
  "x86_64-darwin": {
    "version": "$x86_64_darwin_version",
    "vscodeVersion": "$x86_64_darwin_vscode_version",
    "url": "$x86_64_darwin_url",
    "sha256": "$x86_64_darwin_sha256"
  },
  "x86_64-linux": {
    "version": "$x86_64_linux_version",
    "vscodeVersion": "$x86_64_linux_vscode_version",
    "url": "$x86_64_linux_url",
    "sha256": "$x86_64_linux_sha256"
  }
}
EOF

  echo "Updated info.json with:"
  echo "  aarch64-darwin: $aarch64_darwin_version"
  echo "  x86_64-darwin: $x86_64_darwin_version"
  echo "  x86_64-linux: $x86_64_linux_version"
}

# Main script execution
main() {
  # Check dependencies
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
  fi

  if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed."
    exit 1
  fi

  # Update the info.json file
  update_info_json
}

main
