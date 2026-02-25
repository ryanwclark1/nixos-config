#!/usr/bin/env bash
# Linting hook: Run linters after code changes

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ]; then
  exit 0
fi

# Resolve relative paths
if [ ! "$FILE_PATH" = /* ]; then
  FILE_PATH="$CWD/$FILE_PATH"
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Lint Python files
if [[ "$FILE_PATH" == *.py ]]; then
  if command -v ruff >/dev/null 2>&1; then
    ruff check "$FILE_PATH" 2>&1 || true
  elif command -v pylint >/dev/null 2>&1; then
    pylint "$FILE_PATH" 2>&1 || true
  fi
fi

# Lint TypeScript/JavaScript files
if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]] || \
   [[ "$FILE_PATH" == *.js ]] || [[ "$FILE_PATH" == *.jsx ]]; then
  if command -v biome >/dev/null 2>&1; then
    biome lint "$FILE_PATH" 2>&1 || true
  elif command -v eslint >/dev/null 2>&1; then
    eslint "$FILE_PATH" 2>&1 || true
  fi
fi

# Lint Nix files
if [[ "$FILE_PATH" == *.nix ]]; then
  if command -v nixpkgs-fmt >/dev/null 2>&1; then
    nixpkgs-fmt --check "$FILE_PATH" 2>&1 || true
  fi
  if command -v statix >/dev/null 2>&1; then
    statix check "$FILE_PATH" 2>&1 || true
  fi
fi

exit 0
