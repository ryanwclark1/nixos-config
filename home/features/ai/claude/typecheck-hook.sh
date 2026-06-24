#!/usr/bin/env bash
# Type checking hook: Run type checkers after code changes

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

# Type check TypeScript files
if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]]; then
  # Check if tsconfig.json exists in project
  if [ -f "$CWD/tsconfig.json" ] || [ -f "$CWD/tsconfig.base.json" ]; then
    run_node_tool "$CWD" tsc --noEmit
  fi
fi

# Type check Python files
if [[ "$FILE_PATH" == *.py ]]; then
  # Check if a Python project/type-checker config exists before running tools.
  if has_python_project "$CWD"; then
    run_python_tool "$CWD" pyrefly check "$FILE_PATH"
    run_python_tool "$CWD" ty check "$FILE_PATH"
    run_python_tool "$CWD" mypy "$FILE_PATH"
  fi
fi

exit 0
