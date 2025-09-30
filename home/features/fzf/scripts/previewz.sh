#!/usr/bin/env bash

set -euo pipefail
if [ -d "$1" ]; then
  if command -v eza >/dev/null 2>&1; then
    eza --tree --level=2 --color=always "$1" | head -200
  else
    ls -la --color=always "$1" 2>/dev/null || tree -L 2 "$1" 2>/dev/null
  fi
elif [ -f "$1" ]; then
  mime="$(file --mime-type -Lb "$1" 2>/dev/null || echo)"
  case "$mime" in
    text/*|application/json|application/xml|application/x-sh|application/x-yaml|application/yaml)
      if command -v bat >/dev/null 2>&1; then
        bat --style=numbers --color=always --line-range :500 "$1"
      else
        sed -n "1,500p" "$1"
      fi
      ;;
    *)
      # Binary/unknown: show type + a safe hex/ascii preview
      file -b "$1" 2>/dev/null || true
      if command -v hexdump >/dev/null 2>&1; then
        hexdump -C -n 1024 "$1"
      elif command -v xxd >/dev/null 2>&1; then
        xxd -g 1 -l 1024 "$1"
      else
        head -c 1024 "$1" | od -An -tx1 -v
      fi
      ;;
  esac
else
  file --brief --mime "$1" 2>/dev/null || true
fi
