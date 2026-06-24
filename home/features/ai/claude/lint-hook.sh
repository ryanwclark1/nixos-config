#!/usr/bin/env bash
# Linting hook: Run linters after code changes

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./hook-common.sh
. "$SCRIPT_DIR/hook-common.sh"

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

if ! FILE_PATH=$(resolve_hook_file_path "$INPUT" "$CWD"); then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Lint Python files
if [[ "$FILE_PATH" == *.py ]]; then
  if has_python_project "$CWD"; then
    if command -v uv >/dev/null 2>&1 || command -v ruff >/dev/null 2>&1; then
      run_python_tool "$CWD" ruff check "$FILE_PATH"
    elif command -v pylint >/dev/null 2>&1; then
      run_python_tool "$CWD" pylint "$FILE_PATH"
    fi
  fi
fi

# Lint TypeScript/JavaScript files
if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]] || \
   [[ "$FILE_PATH" == *.js ]] || [[ "$FILE_PATH" == *.jsx ]]; then
  if node_tool_available "$CWD" biome; then
    run_node_tool "$CWD" biome lint "$FILE_PATH"
  elif node_tool_available "$CWD" eslint; then
    run_node_tool "$CWD" eslint "$FILE_PATH"
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
