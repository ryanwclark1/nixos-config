#!/usr/bin/env bash
# Security hook: Block dangerous commands and protect sensitive files

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Block dangerous Bash commands
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Block destructive commands
  DANGEROUS_PATTERNS=(
    "rm -rf /"
    "rm -rf ~"
    "rm -rf /home"
    "rm -rf /usr"
    "rm -rf /etc"
    "rm -rf /var"
    "dd if="
    "mkfs"
    "fdisk"
    "format"
    ":(){ :|:& };:"  # Fork bomb
  )

  for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qi "$pattern"; then
      jq -n '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: "Dangerous command blocked: '"$pattern"'"
        }
      }'
      exit 2
    fi
  done
fi

# Block edits to sensitive files
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.file_path // empty')

  PROTECTED_PATTERNS=(
    ".env"
    ".env.*"
    "secrets/"
    ".git/"
    "*.key"
    "*.pem"
    "*.secret"
    "package-lock.json"  # Often auto-generated
    "yarn.lock"          # Often auto-generated
  )

  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qiE "$pattern"; then
      jq -n '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: "Protected file pattern blocked: '"$pattern"'"
        }
      }'
      exit 2
    fi
  done
fi

exit 0
