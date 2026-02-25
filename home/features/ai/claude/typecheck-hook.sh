#!/usr/bin/env bash
# Type checking hook: Run type checkers after code changes

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

# Type check TypeScript files
if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]]; then
  if command -v tsc >/dev/null 2>&1; then
    # Check if tsconfig.json exists in project
    if [ -f "$CWD/tsconfig.json" ] || [ -f "$CWD/tsconfig.base.json" ]; then
      tsc --noEmit 2>&1 | grep -E "(error TS|$FILE_PATH)" || true
    fi
  fi
fi

# Type check Python files
if [[ "$FILE_PATH" == *.py ]]; then
  if command -v mypy >/dev/null 2>&1; then
    # Check if pyproject.toml or mypy.ini exists
    if [ -f "$CWD/pyproject.toml" ] || [ -f "$CWD/mypy.ini" ] || [ -f "$CWD/.mypy.ini" ]; then
      mypy "$FILE_PATH" 2>&1 || true
    fi
  fi
fi

exit 0
