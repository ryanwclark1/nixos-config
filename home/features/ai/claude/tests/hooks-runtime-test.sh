#!/usr/bin/env bash
# Runtime-selection smoke tests for Claude Code hooks.

set -euo pipefail

REPO_ROOT=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)
HOOK_DIR="$REPO_ROOT/home/features/ai/claude"

TMPDIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

PROJECT="$TMPDIR/project"
BIN="$TMPDIR/bin"
LOG="$TMPDIR/hooks.log"

mkdir -p "$PROJECT/node_modules/.bin" "$BIN"
touch "$PROJECT/pyproject.toml" "$PROJECT/package.json" "$PROJECT/tsconfig.json"
cat >"$PROJECT/example.py" <<'PY'
def add(left: int, right: int) -> int:
    return left + right
PY
cat >"$PROJECT/example.ts" <<'TS'
export const value: number = 1;
TS

cat >"$BIN/uv" <<'SH'
#!/usr/bin/env bash
printf 'uv %s\n' "$*" >>"$CLAUDE_HOOK_TEST_LOG"
if [ "$1" = "run" ]; then
  shift
  if [ "${1:-}" = "--no-sync" ]; then
    shift
  fi
fi
"$@"
SH
chmod +x "$BIN/uv"

for tool in ruff pyrefly ty mypy; do
  cat >"$BIN/$tool" <<'SH'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >>"$CLAUDE_HOOK_TEST_LOG"
exit 0
SH
  chmod +x "$BIN/$tool"
done

cat >"$BIN/fnm" <<'SH'
#!/usr/bin/env bash
case "$1" in
  env)
    printf 'export CLAUDE_HOOK_FNM=1\n'
    ;;
  use)
    printf 'fnm %s\n' "$*" >>"$CLAUDE_HOOK_TEST_LOG"
    ;;
esac
SH
chmod +x "$BIN/fnm"

cat >"$PROJECT/node_modules/.bin/tsc" <<'SH'
#!/usr/bin/env bash
printf 'tsc FNM=%s %s\n' "${CLAUDE_HOOK_FNM:-0}" "$*" >>"$CLAUDE_HOOK_TEST_LOG"
exit 0
SH
chmod +x "$PROJECT/node_modules/.bin/tsc"

run_hook() {
  local hook=$1
  local path=$2

  CLAUDE_HOOK_TEST_LOG="$LOG" \
  PATH="$BIN:$PATH" \
    bash "$HOOK_DIR/$hook" <<JSON
{"cwd":"$PROJECT","tool_input":{"path":"$path"}}
JSON
}

run_hook format-hook.sh example.py
run_hook lint-hook.sh example.py
run_hook typecheck-hook.sh example.py
run_hook typecheck-hook.sh example.ts

grep -Fx "uv run --no-sync ruff format $PROJECT/example.py" "$LOG"
grep -Fx "uv run --no-sync ruff check $PROJECT/example.py" "$LOG"
grep -Fx "uv run --no-sync pyrefly check $PROJECT/example.py" "$LOG"
grep -Fx "uv run --no-sync ty check $PROJECT/example.py" "$LOG"
grep -Fx "uv run --no-sync mypy $PROJECT/example.py" "$LOG"
grep -Fx "fnm use --silent-if-unchanged" "$LOG"
grep -Fx "tsc FNM=1 --noEmit" "$LOG"
