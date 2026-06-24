#!/usr/bin/env bash
# Format hook for Python and TypeScript files
# This hook runs after file writes to automatically format code

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./hook-common.sh
. "$SCRIPT_DIR/hook-common.sh"

# Read JSON input from stdin
INPUT=$(cat)

# Get current working directory from hook input
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

if ! FILE_PATH=$(resolve_hook_file_path "$INPUT" "$CWD"); then
  exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Format Python files
if [[ "$FILE_PATH" == *.py ]]; then
  if has_python_project "$CWD"; then
    if command -v uv >/dev/null 2>&1 || command -v ruff >/dev/null 2>&1; then
      run_python_tool "$CWD" ruff format "$FILE_PATH"
    elif command -v black >/dev/null 2>&1; then
      run_python_tool "$CWD" black "$FILE_PATH"
    fi
  fi
fi

# Format TypeScript/JavaScript files
if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]] || \
   [[ "$FILE_PATH" == *.js ]] || [[ "$FILE_PATH" == *.jsx ]]; then
  if node_tool_available "$CWD" biome; then
    run_node_tool "$CWD" biome format --write "$FILE_PATH"
  elif node_tool_available "$CWD" prettier; then
    run_node_tool "$CWD" prettier --write "$FILE_PATH"
  fi
fi

exit 0
