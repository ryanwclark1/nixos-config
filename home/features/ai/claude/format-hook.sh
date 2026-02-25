#!/usr/bin/env bash
# Format hook for Python and TypeScript files
# This hook runs after file writes to automatically format code

set -euo pipefail

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
# Try multiple possible field names for file path
FILE_PATH=$(echo "$INPUT" | jq -r '
  .tool_input.path //
  .tool_input.file_path //
  .tool_input.file //
  .tool_input.target //
  empty
')

# Exit if no file path found
if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" = "null" ] || [ "$FILE_PATH" = "" ]; then
  exit 0
fi

# Get current working directory from hook input
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')

# Resolve file path relative to CWD if needed
if [ ! "$FILE_PATH" = /* ]; then
  FILE_PATH="$CWD/$FILE_PATH"
fi

# Normalize path (remove .. and .) - use realpath if available, otherwise use cd
if command -v realpath >/dev/null 2>&1; then
  FILE_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
else
  # Fallback: use cd to resolve relative paths
  FILE_PATH=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd)/$(basename "$FILE_PATH") 2>/dev/null || echo "$FILE_PATH")
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Format Python files
if [[ "$FILE_PATH" == *.py ]]; then
  if command -v ruff >/dev/null 2>&1; then
    ruff format "$FILE_PATH" 2>&1 || true
  elif command -v black >/dev/null 2>&1; then
    black "$FILE_PATH" 2>&1 || true
  fi
fi

# Format TypeScript/JavaScript files
if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]] || \
   [[ "$FILE_PATH" == *.js ]] || [[ "$FILE_PATH" == *.jsx ]]; then
  # Prefer Biome for formatting (faster and includes linting)
  if command -v biome >/dev/null 2>&1; then
    biome format --write "$FILE_PATH" 2>&1 || true
  # Fall back to Prettier if Biome isn't available
  elif command -v prettier >/dev/null 2>&1; then
    prettier --write "$FILE_PATH" 2>&1 || true
  fi

  # Optional: Run TypeScript compiler type checking (doesn't format, but validates types)
  # Uncomment if you want type checking after formatting
  # if [[ "$FILE_PATH" == *.ts ]] || [[ "$FILE_PATH" == *.tsx ]]; then
  #   if command -v tsc >/dev/null 2>&1; then
  #     tsc --noEmit "$FILE_PATH" 2>&1 || true
  #   fi
  # fi
fi

exit 0
