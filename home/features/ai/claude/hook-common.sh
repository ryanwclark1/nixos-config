#!/usr/bin/env bash
# Shared helpers for Claude Code hooks.

resolve_hook_file_path() {
  local input=$1
  local cwd=$2
  local file_path

  file_path=$(echo "$input" | jq -r '
    .tool_input.path //
    .tool_input.file_path //
    .tool_input.file //
    .tool_input.target //
    empty
  ')

  if [ -z "$file_path" ] || [ "$file_path" = "null" ]; then
    return 1
  fi

  if [[ "$file_path" != /* ]]; then
    file_path="$cwd/$file_path"
  fi

  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$file_path" 2>/dev/null || echo "$file_path"
  else
    local dir
    dir=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd) || {
      echo "$file_path"
      return 0
    }
    echo "$dir/$(basename "$file_path")"
  fi
}

has_python_project() {
  local cwd=$1

  [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/uv.lock" ] || \
    [ -f "$cwd/pyrefly.toml" ] || [ -f "$cwd/ty.toml" ] || \
    [ -f "$cwd/mypy.ini" ] || [ -f "$cwd/.mypy.ini" ] || \
    [ -f "$cwd/pyrightconfig.json" ] || [ -f "$cwd/setup.py" ]
}

run_python_tool() {
  local cwd=$1
  local tool=$2
  shift 2

  if command -v uv >/dev/null 2>&1 && { [ -f "$cwd/pyproject.toml" ] || [ -f "$cwd/uv.lock" ]; }; then
    (cd "$cwd" && uv run --no-sync "$tool" "$@") 2>&1 || true
  elif command -v "$tool" >/dev/null 2>&1; then
    (cd "$cwd" && "$tool" "$@") 2>&1 || true
  fi
}

init_node_runtime() {
  local cwd=$1

  if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)" || true
    (cd "$cwd" && fnm use --silent-if-unchanged >/dev/null 2>&1) || true
  elif [ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"
    (cd "$cwd" && nvm use --silent >/dev/null 2>&1) || true
  fi
}

run_node_tool() {
  local cwd=$1
  local tool=$2
  shift 2

  init_node_runtime "$cwd"

  if [ -x "$cwd/node_modules/.bin/$tool" ]; then
    (cd "$cwd" && "node_modules/.bin/$tool" "$@") 2>&1 || true
  elif command -v pnpm >/dev/null 2>&1 && [ -f "$cwd/pnpm-lock.yaml" ]; then
    (cd "$cwd" && pnpm exec "$tool" "$@") 2>&1 || true
  elif command -v npx >/dev/null 2>&1 && { [ -f "$cwd/package-lock.json" ] || [ -f "$cwd/npm-shrinkwrap.json" ]; }; then
    (cd "$cwd" && npx --no-install "$tool" "$@") 2>&1 || true
  elif command -v yarn >/dev/null 2>&1 && [ -f "$cwd/yarn.lock" ]; then
    (cd "$cwd" && yarn exec "$tool" "$@") 2>&1 || true
  elif command -v "$tool" >/dev/null 2>&1; then
    (cd "$cwd" && "$tool" "$@") 2>&1 || true
  fi
}

node_tool_available() {
  local cwd=$1
  local tool=$2

  [ -x "$cwd/node_modules/.bin/$tool" ] || command -v "$tool" >/dev/null 2>&1
}
