#!/usr/bin/env bash
# Helper script to export CONTEXT7_TOKEN from SOPS secrets
# Source this in your shell profile: source ~/nixos-config/scripts/set-context7-token.sh

# Try to find the SOPS secret path
# The path is typically in one of these locations after NixOS rebuilds:
SOPS_PATHS=(
  "$HOME/.config/sops/context7-token"
  "/run/user/$(id -u)/secrets/context7-token"
  "$HOME/.local/share/sops-nix/secrets/context7-token"
)

CONTEXT7_TOKEN=""
for path in "${SOPS_PATHS[@]}"; do
  if [ -f "$path" ]; then
    CONTEXT7_TOKEN=$(cat "$path" 2>/dev/null)
    if [ -n "$CONTEXT7_TOKEN" ]; then
      export CONTEXT7_TOKEN
      echo "✓ CONTEXT7_TOKEN exported from $path"
      return 0 2>/dev/null || exit 0
    fi
  fi
done

# If not found, try to decrypt from secrets.yaml directly
SECRETS_FILE="$HOME/nixos-config/secrets/secrets.yaml"
if [ -f "$SECRETS_FILE" ] && command -v sops >/dev/null 2>&1; then
  CONTEXT7_TOKEN=$(sops -d "$SECRETS_FILE" 2>/dev/null | grep -A 1 "context7-token:" | tail -1 | sed 's/^[[:space:]]*//')
  if [ -n "$CONTEXT7_TOKEN" ]; then
    export CONTEXT7_TOKEN
    echo "✓ CONTEXT7_TOKEN exported from SOPS secrets.yaml"
    return 0 2>/dev/null || exit 0
  fi
fi

echo "⚠ Warning: Could not find CONTEXT7_TOKEN. Claude Code MCP server may not work."
echo "  Make sure NixOS has been rebuilt and SOPS secrets are available."
return 1 2>/dev/null || exit 1
