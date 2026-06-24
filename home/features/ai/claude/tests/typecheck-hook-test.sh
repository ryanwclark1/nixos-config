#!/usr/bin/env bash
# Smoke tests for the Claude typecheck hook.

set -euo pipefail

REPO_ROOT=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
HOOK="$REPO_ROOT/home/features/ai/claude/typecheck-hook.sh"

TMPDIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

PROJECT="$TMPDIR/project"
BIN="$TMPDIR/bin"
LOG="$TMPDIR/typecheck.log"

mkdir -p "$PROJECT" "$BIN"
touch "$PROJECT/pyproject.toml"
cat >"$PROJECT/example.py" <<'PY'
def add(left: int, right: int) -> int:
    return left + right
PY

make_fake_checker() {
  local name=$1
  cat >"$BIN/$name" <<'SH'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >>"$TYPECHECK_HOOK_LOG"
exit 0
SH
  chmod +x "$BIN/$name"
}

make_fake_checker pyrefly
make_fake_checker ty
make_fake_checker mypy

TYPECHECK_HOOK_LOG="$LOG" \
PATH="$BIN:$PATH" \
  bash "$HOOK" <<JSON
{"cwd":"$PROJECT","tool_input":{"path":"example.py"}}
JSON

grep -Fx "pyrefly check $PROJECT/example.py" "$LOG"
grep -Fx "ty check $PROJECT/example.py" "$LOG"
grep -Fx "mypy $PROJECT/example.py" "$LOG"
