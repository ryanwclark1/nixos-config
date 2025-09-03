#!/usr/bin/env bash

# Open URL in default browser or as webapp
# Supports both regular browser mode and webapp mode

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Usage: open-url <URL> [--webapp]"
  echo "  --webapp    Launch in webapp mode if supported"
  exit 1
fi

url="$1"
webapp_mode=false

# Check for webapp flag
if [[ "${2:-}" == "--webapp" ]]; then
  webapp_mode=true
fi

# Add https:// if no protocol specified
if [[ ! "$url" =~ ^https?:// ]]; then
  url="https://$url"
fi

if [[ "$webapp_mode" == true ]]; then
  echo "Opening as webapp: $url"
  launch-webapp "$url"
else
  echo "Opening in browser: $url"
  launch-browser "$url"
fi