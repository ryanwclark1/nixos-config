#!/usr/bin/env bash
# Git safety hook: Prevent dangerous git operations

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block force push to main/master
if echo "$COMMAND" | grep -qiE "git push.*--force.*(main|master)"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Force push to main/master branch is blocked for safety"
    }
  }'
  exit 2
fi

# Block force push without --force-with-lease
if echo "$COMMAND" | grep -qiE "git push.*--force(?!.*--force-with-lease)"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Use --force-with-lease instead of --force for safer force pushes"
    }
  }'
  exit 2
fi

# Warn about git reset --hard
if echo "$COMMAND" | grep -qiE "git reset.*--hard"; then
  echo "Warning: git reset --hard will discard uncommitted changes" >&2
fi

exit 0
