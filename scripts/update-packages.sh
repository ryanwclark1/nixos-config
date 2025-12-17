#!/usr/bin/env bash
# Master script to update all custom packages
# Usage: ./scripts/update-packages.sh [package-name]
#   If package-name is provided, only update that package
#   If no argument, update all packages

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Package definitions: name, directory, update script
declare -A PACKAGES=(
  [code-cursor]="pkgs/code-cursor"
  [cursor-cli]="pkgs/cursor-cli"
  [gemini-cli]="pkgs/gemini-cli"
  [claude-code]="pkgs/claude-code"
  [codex]="pkgs/codex"
  [antigravity]="pkgs/antigravity"
  [kiro]="pkgs/kiro"
  [vscode-generic]="pkgs/vscode-generic"
)

# Function to print colored output
info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✅${NC} $1"; }
warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; }

# Function to update a single package
update_package() {
  local pkg_name=$1
  local pkg_dir="${PACKAGES[$pkg_name]}"

  if [[ -z "$pkg_dir" ]]; then
    error "Unknown package: $pkg_name"
    return 1
  fi

  local full_path="$REPO_ROOT/$pkg_dir"
  local update_script="$full_path/update.sh"

  if [[ ! -f "$update_script" ]]; then
    error "Update script not found: $update_script"
    return 1
  fi

  info "Checking $pkg_name for updates..."
  echo ""

  cd "$full_path"
  local output
  if output=$(bash "$update_script" 2>&1); then
    # Check if the script reported "Already up to date"
    if echo "$output" | grep -q "Already up to date\|No update\|is already in"; then
      echo "$output" | grep -E "(Already up to date|No update|is already in)" || true
      echo ""
      return 0
    else
      # Package was actually updated
      echo "$output"
      success "$pkg_name updated successfully"
      echo ""
      return 0
    fi
  else
    error "$pkg_name update failed"
    echo "$output" || true
    echo ""
    return 1
  fi
}

# Function to check for updates (dry run)
check_updates() {
  local pkg_name=$1
  local pkg_dir="${PACKAGES[$pkg_name]}"
  local full_path="$REPO_ROOT/$pkg_dir"
  local update_script="$full_path/update.sh"

  if [[ ! -f "$update_script" ]]; then
    return 1
  fi

  # Try to run the update script and capture if it says "Already up to date"
  cd "$full_path"
  if output=$(bash "$update_script" 2>&1); then
    if echo "$output" | grep -q "Already up to date"; then
      return 1  # No update needed
    else
      return 0  # Update available
    fi
  fi
  return 1
}

# Function to show status of all packages
show_status() {
  info "Checking for updates across all packages..."
  echo ""

  local updates_available=()
  local up_to_date=()

  for pkg in "${!PACKAGES[@]}"; do
    if check_updates "$pkg"; then
      updates_available+=("$pkg")
      echo -e "  ${YELLOW}●${NC} $pkg - Update available"
    else
      up_to_date+=("$pkg")
      echo -e "  ${GREEN}●${NC} $pkg - Up to date"
    fi
  done

  echo ""
  if [[ ${#updates_available[@]} -eq 0 ]]; then
    success "All packages are up to date!"
  else
    info "Packages with updates available: ${updates_available[*]}"
    echo ""
    echo "Run: $0 update ${updates_available[*]}"
    echo "Or:  $0 update-all"
  fi
}

# Main execution
cd "$REPO_ROOT"

case "${1:-}" in
  ""|status|check)
    show_status
    ;;
  update|upgrade)
    if [[ -z "${2:-}" ]]; then
      error "Please specify a package name or use 'update-all'"
      echo ""
      echo "Available packages:"
      for pkg in "${!PACKAGES[@]}"; do
        echo "  - $pkg"
      done
      exit 1
    fi

    shift
    for pkg in "$@"; do
      if [[ "$pkg" == "all" ]]; then
        # Update all packages
        for pkg_name in "${!PACKAGES[@]}"; do
          update_package "$pkg_name" || true
        done
      else
        update_package "$pkg" || true
      fi
    done
    ;;
  update-all|upgrade-all)
    info "Updating all packages..."
    echo ""
    for pkg in "${!PACKAGES[@]}"; do
      update_package "$pkg" || true
      echo "---"
    done
    success "All packages processed!"
    ;;
  list)
    echo "Available packages:"
    for pkg in "${!PACKAGES[@]}"; do
      pkg_dir="${PACKAGES[$pkg]}"
      version_file="$REPO_ROOT/$pkg_dir/default.nix"
      version="unknown"

      if [[ -f "$version_file" ]]; then
        # Try to get version from default.nix
        version=$(grep -E '^\s*version\s*=' "$version_file" 2>/dev/null | sed -E 's/.*version\s*=\s*"([^"]+)".*/\1/' | head -1 || echo "")
      fi

      # Special case for antigravity which uses information.json
      if [[ "$pkg" == "antigravity" ]] && [[ -z "$version" || "$version" == "unknown" ]]; then
        info_file="$REPO_ROOT/$pkg_dir/information.json"
        if [[ -f "$info_file" ]]; then
          version=$(jq -r '.version' "$info_file" 2>/dev/null || echo "unknown")
        fi
      fi

      if [[ -n "$version" && "$version" != "unknown" ]]; then
        echo "  - $pkg (v$version)"
      else
        echo "  - $pkg"
      fi
    done | sort
    ;;
  *)
    echo "Usage: $0 [command] [package-name...]"
    echo ""
    echo "Commands:"
    echo "  status, check          Check which packages have updates available"
    echo "  update <package>       Update a specific package"
    echo "  update-all             Update all packages"
    echo "  list                   List all available packages with versions"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 update code-cursor"
    echo "  $0 update code-cursor cursor-cli"
    echo "  $0 update-all"
    exit 1
    ;;
esac

