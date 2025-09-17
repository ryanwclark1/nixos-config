#!/usr/bin/env bash
# Claude Code status line styled like a Starship "powerline" prompt.

# -------- Config (tweak colors/modules here) ------------------
# Catppuccin Frappé palette matching Starship configuration
  BASE00="\e[38;2;48;52;70m"         # base (text on colored backgrounds)
  BASE0E="\e[38;2;202;158;230m"      # mauve (primary segment bg)
  BASE07="\e[38;2;186;187;241m"      # lavender (directory bg)
  BASE05="\e[38;2;198;208;245m"      # text (git bg)
  BASE0F="\e[38;2;238;190;190m"      # flamingo (languages bg)
  BASE06="\e[38;2;242;213;207m"      # rosewater (docker/nix bg)

# Background colors
  BG_BASE0E="\e[48;2;202;158;230m"   # mauve background
  BG_BASE07="\e[48;2;186;187;241m"   # lavender background
  BG_BASE05="\e[48;2;198;208;245m"   # text background
  BG_BASE0F="\e[48;2;238;190;190m"   # flamingo background
  BG_BASE06="\e[48;2;242;213;207m"   # rosewater background

# Utility colors
FG_DIM="\e[2m"
FG_RESET="\e[0m"

# Powerline glyphs
SEP_LEFT="\uE0B6"   # 
SEP_RIGHT="\uE0B4"  # 

# Toggle modules (set to 0 to disable)
SHOW_OS=1
SHOW_USER=0
SHOW_HOST=0
SHOW_LOCAL_IP=0
SHOW_CONTAINER=1
SHOW_DIR=1
SHOW_GIT=1
SHOW_DOCKER=1
SHOW_TIME=0
SHOW_NIX_SHELL=0
SHOW_COST=0
SHOW_MODEL=1
SHOW_DURATION=0
SHOW_HOOK_EVENT=1
SHOW_SESSION=0
SHOW_OUTPUT_STYLE=0

# Individual language toggles
SHOW_PYTHON=0
SHOW_NODE=0
SHOW_RUST=0
SHOW_GO=0
SHOW_DENO=0
SHOW_BUN=0
SHOW_C=0
SHOW_JAVA=0
SHOW_KOTLIN=0
SHOW_LUA=0
SHOW_PHP=0
SHOW_SWIFT=0
SHOW_ZIG=0

# Performance: keep git checks cheap
GIT_TIMEOUT=80   # ms budget for git calls (best-effort)
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
CACHE_TTL=5      # Cache TTL in seconds for expensive operations

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR" 2>/dev/null

# ------------- Helpers ---------------------------------------
# Read the JSON once (Claude sends session info on stdin)
INPUT="$(cat 2>/dev/null)"
# Extract workspace cwd with jq if available; fallback to $PWD
if command -v jq >/dev/null 2>&1; then
  CWD="$(printf '%s' "$INPUT" | jq -r '.workspace.current_dir // empty')"
fi
CWD="${CWD:-$PWD}"

# Claude Code JSON helper functions
get_model_name() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.model.display_name // .model // empty'
  fi
}
get_current_dir() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.workspace.current_dir // empty'
  fi
}
get_project_dir() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.workspace.project_dir // empty'
  fi
}
get_version() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.version // empty'
  fi
}
get_cost() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.cost.total_cost_usd // empty'
  fi
}
get_duration() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.cost.total_duration_ms // empty'
  fi
}
get_lines_added() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.cost.total_lines_added // empty'
  fi
}
get_lines_removed() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.cost.total_lines_removed // empty'
  fi
}
get_session_id() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.session.id // empty'
  fi
}
get_hook_event() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.hook.event_name // .hook.event // empty'
  fi
}
get_output_style() {
  if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
    printf '%s' "$INPUT" | jq -r '.output_style // empty'
  fi
}

basename_fast() { printf '%s' "${1##*/}"; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# Caching utilities for expensive operations
cache_get() {
  local key="$1"
  local cache_file="$CACHE_DIR/$key"
  if [ -f "$cache_file" ]; then
    # Use a more portable approach for checking file age
    local cache_time current_time
    if command -v stat >/dev/null 2>&1; then
      # Try Linux stat first, then macOS stat
      cache_time="$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)"
    fi
    # Fallback if stat fails
    if [ -z "$cache_time" ]; then
      # Simple existence check - just use the cache if it exists
      cat "$cache_file"
      return 0
    fi
    current_time="$(date +%s)"
    if [ "$cache_time" ] && [ "$current_time" ] && [ $((current_time - cache_time)) -lt $CACHE_TTL ]; then
      cat "$cache_file"
      return 0
    fi
  fi
  return 1
}

cache_set() {
  local key="$1"
  local value="$2"
  local cache_file="$CACHE_DIR/$key"
  printf '%s' "$value" > "$cache_file" 2>/dev/null
}

# Cheap local IP (prefers non-loopback)
local_ip() {
  if has_cmd ip; then
    ip -4 -o addr show scope global 2>/dev/null \
      | awk '{print $4}' | cut -d/ -f1 | head -n1
  elif has_cmd ifconfig; then
    ifconfig 2>/dev/null | awk '/inet / && $2!="127.0.0.1"{print $2; exit}'
  fi
}

in_container() {
  # Common heuristics
  if [ -f "/.dockerenv" ]; then return 0; fi
  grep -qi 'docker\|lxc\|containerd' /proc/1/cgroup 2>/dev/null && return 0
  return 1
}

git_branch() {
  # Use caching for git branch to avoid repeated expensive operations
  local pwd_hash; pwd_hash="$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)"
  local cache_key="git_branch_${pwd_hash}"

  # Try cache first
  local cached_result; cached_result="$(cache_get "$cache_key")"
  if [ $? -eq 0 ]; then
    printf '%s' "$cached_result"
    return 0
  fi

  local branch=""
  # Very fast branch check without invoking multiple processes when possible
  if [ -d ".git" ]; then
    # Detached/head read
    local head; head=$(2>/dev/null < .git/HEAD tr -d '\n')
    case "$head" in
      ref:\ refs/heads/*) branch="${head#ref: refs/heads/}";;
    esac
  fi

  # Fallback to git (with a timeout) if direct read failed
  if [ -z "$branch" ] && has_cmd git; then
    ( git branch --show-current 2>/dev/null & pid=$!; \
      sleep 0.$GIT_TIMEOUT; kill -0 $pid 2>/dev/null && kill $pid 2>/dev/null; true ) >/dev/null
    branch="$(git branch --show-current 2>/dev/null)"
  fi

  # Cache result
  cache_set "$cache_key" "$branch"
  printf '%s' "$branch"
}

git_status_info() {
  # Enhanced git status matching Starship's git_status module with caching
  if has_cmd git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local pwd_hash; pwd_hash="$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)"
    local cache_key="git_status_${pwd_hash}"

    # Try cache first
    local cached_result; cached_result="$(cache_get "$cache_key")"
    if [ $? -eq 0 ]; then
      printf '%s' "$cached_result"
      return 0
    fi

    local status; status="$(git status --porcelain=v1 2>/dev/null)"
    local ahead_behind=""

    # Check for ahead/behind (most expensive operation)
    if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
      local ahead; ahead="$(git rev-list --count '@{upstream}..HEAD' 2>/dev/null)"
      local behind; behind="$(git rev-list --count 'HEAD..@{upstream}' 2>/dev/null)"
      [ "$ahead" -gt 0 ] && ahead_behind+="⇡${ahead}"
      [ "$behind" -gt 0 ] && ahead_behind+="⇣${behind}"
    fi

    # Parse status efficiently
    local all_status=""
    [ -n "$(echo "$status" | grep '^[MADRC]')" ] && all_status+="●"
    [ -n "$(echo "$status" | grep '^ [MD]')" ] && all_status+="!"
    [ -n "$(echo "$status" | grep '^??')" ] && all_status+="?"
    [ -n "$(echo "$status" | grep '^ R')" ] && all_status+="»"

    local result="${all_status}${ahead_behind}"
    cache_set "$cache_key" "$result"
    printf '%s' "$result"
  fi
}

docker_context() {
  if has_cmd docker; then
    # Cache docker context since it rarely changes during a session
    local cache_key="docker_context"
    local cached_result; cached_result="$(cache_get "$cache_key")"
    if [ $? -eq 0 ]; then
      printf '%s' "$cached_result"
      return 0
    fi

    local ctx; ctx="$(docker context show 2>/dev/null)"
    local result=""
    [ -n "$ctx" ] && result=" $ctx"

    cache_set "$cache_key" "$result"
    printf '%s' "$result"
  fi
}


lang_badges() {
  # Cache language versions since they rarely change
  local cache_key="lang_versions"
  local cached_result; cached_result="$(cache_get "$cache_key")"
  if [ $? -eq 0 ]; then
    printf '%s' "$cached_result"
    return 0
  fi

  local out=""
  # Python venv / version
  if [ $SHOW_PYTHON -eq 1 ] && ([ -n "$VIRTUAL_ENV" ] || has_cmd python3); then
    local pyv; pyv="$(python3 -V 2>/dev/null | awk '{print $2}')"
    local venv_name=""
    [ -n "$VIRTUAL_ENV" ] && venv_name="($(basename "$VIRTUAL_ENV"))"
    [ -n "$pyv" ] && out+="${out:+ } ${pyv}${venv_name:+ $venv_name}"
  fi
  # Node
  if [ $SHOW_NODE -eq 1 ] && has_cmd node; then
    local nv; nv="$(node -v 2>/dev/null)"
    [ -n "$nv" ] && out+="${out:+ } ${nv#v}"
  fi
  # Rust
  if [ $SHOW_RUST -eq 1 ] && has_cmd rustc; then
    local rv; rv="$(rustc --version 2>/dev/null | awk '{print $2}')"
    [ -n "$rv" ] && out+="${out:+ } ${rv}"
  fi
  # Go
  if [ $SHOW_GO -eq 1 ] && has_cmd go; then
    local gv; gv="$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')"
    [ -n "$gv" ] && out+="${out:+ } ${gv}"
  fi
  # Deno
  if [ $SHOW_DENO -eq 1 ] && has_cmd deno; then
    local dv; dv="$(deno --version 2>/dev/null | head -n1 | awk '{print $2}')"
    [ -n "$dv" ] && out+="${out:+ } ${dv}"
  fi
  # Bun
  if [ $SHOW_BUN -eq 1 ] && has_cmd bun; then
    local bv; bv="$(bun --version 2>/dev/null)"
    [ -n "$bv" ] && out+="${out:+ } ${bv}"
  fi
  # C compiler
  if [ $SHOW_C -eq 1 ] && has_cmd gcc; then
    local cv; cv="$(gcc --version 2>/dev/null | head -n1 | awk '{print $4}')"
    [ -n "$cv" ] && out+="${out:+ } ${cv}"
  fi
  # Java
  if [ $SHOW_JAVA -eq 1 ] && has_cmd java; then
    local jv; jv="$(java -version 2>&1 | head -n1 | awk -F'"' '{print $2}')"
    [ -n "$jv" ] && out+="${out:+ } ${jv}"
  fi
  # Kotlin
  if [ $SHOW_KOTLIN -eq 1 ] && has_cmd kotlin; then
    local kv; kv="$(kotlin -version 2>/dev/null | awk '{print $3}')"
    [ -n "$kv" ] && out+="${out:+ } ${kv}"
  fi
  # Lua
  if [ $SHOW_LUA -eq 1 ] && has_cmd lua; then
    local lv; lv="$(lua -v 2>/dev/null | head -n1 | awk '{print $2}')"
    [ -n "$lv" ] && out+="${out:+ } ${lv}"
  fi
  # PHP
  if [ $SHOW_PHP -eq 1 ] && has_cmd php; then
    local pv; pv="$(php -v 2>/dev/null | head -n1 | awk '{print $2}')"
    [ -n "$pv" ] && out+="${out:+ } ${pv}"
  fi
  # Swift
  if [ $SHOW_SWIFT -eq 1 ] && has_cmd swift; then
    local sv; sv="$(swift --version 2>/dev/null | head -n1 | awk '{print $4}')"
    [ -n "$sv" ] && out+="${out:+ } ${sv}"
  fi
  # Zig
  if [ $SHOW_ZIG -eq 1 ] && has_cmd zig; then
    local zv; zv="$(zig version 2>/dev/null)"
    [ -n "$zv" ] && out+="${out:+ } ${zv}"
  fi

  # Cache for longer since versions change infrequently
  cache_set "$cache_key" "$out"
  printf '%s' "$out"
}

claude_info() {
  if [ -n "$INPUT" ] && ([ $SHOW_CLAUDE -eq 1 ] || [ $SHOW_MODEL -eq 1 ] || [ $SHOW_COST -eq 1 ] || [ $SHOW_DURATION -eq 1 ] || [ $SHOW_SESSION -eq 1 ]); then
    local claude_context=""
    # Use helper functions for cleaner extraction
    local model; model="$(get_model_name)"
    local session; session="$(printf '%s' "$INPUT" | jq -r '.session.id // empty' 2>/dev/null | head -c 8)"
    local cost; cost="$(get_cost)"
    local duration; duration="$(get_duration)"

    # Build context string using individual toggles
    [ $SHOW_MODEL -eq 1 ] && [ -n "$model" ] && claude_context+="$model"
    [ $SHOW_SESSION -eq 1 ] && [ -n "$session" ] && claude_context+="${claude_context:+ }#$session"

    # Add cost/duration if individual toggles are enabled
    if [ $SHOW_COST -eq 1 ] && [ -n "$cost" ] && [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
      local formatted_cost; formatted_cost="$(printf "%.3f" "$cost")"
      claude_context+="${claude_context:+ }\$${formatted_cost}"
    fi
    if [ $SHOW_DURATION -eq 1 ] && [ -n "$duration" ] && [ "$duration" != "0" ] && [ "$duration" != "null" ]; then
      local dur_sec; dur_sec="$((duration / 1000))"
      claude_context+="${claude_context:+ }${dur_sec}s"
    fi

    [ -n "$claude_context" ] && printf " %s" "$claude_context"
  fi
}

# Right-align: Claude renders a single line; we fake a "fill" with spaces.
# We'll compute a small padding; exact width is unknown, so we insert a spacer.
spacer() { printf ' %s ' "$(printf '%.0s·' $(seq 1 10))"; }

# ------------- Build segments --------------------------------
# Powerline segment transitions matching Starship configuration
# Format: [](fg:COLOR) for left separator, [](bg:FROM_COLOR fg:TO_COLOR) for transitions

s_os()        {
  if [ $SHOW_OS -eq 1 ]; then
    case "$(uname -s)" in
      Linux)
        # Check for specific distro - matches your Starship config exactly
        if [ -f /etc/os-release ]; then
          . /etc/os-release
          case "$ID" in
            nixos) printf " " ;;
            arch) printf "󰣇" ;;
            artix) printf "󰣇" ;;
            ubuntu) printf "󰕈 " ;;
            fedora) printf "󰣛 " ;;
            debian) printf " " ;;
            almalinux) printf " " ;;
            alpine) printf " " ;;
            centos) printf " " ;;
            freebsd) printf " " ;;
            gentoo) printf "󰣨 " ;;
            kali) printf " " ;;
            manjaro) printf " " ;;
            mint) printf "󰣭 " ;;
            pop) printf " " ;;
            raspbian) printf " " ;;
            redhat) printf " " ;;
            rhel) printf "󱄛" ;;
            rocky) printf " " ;;
            suse) printf " " ;;
            void) printf " " ;;
            *) printf "󰌽" ;;
          esac
        else
          printf "󰌽"
        fi
        ;;
      Darwin) printf "󰀵" ;;
      CYGWIN*|MINGW*|MSYS*) printf "󰍲 " ;;
      *) printf "$(uname -s)" ;;
    esac
  fi
}
s_user()      { [ $SHOW_USER -eq 1 ] && printf "%s" "$USER"; }
s_host()      {
  if [ $SHOW_HOST -eq 1 ]; then
    local hostname; hostname="$(hostname -s 2>/dev/null || hostname)"
    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
      printf " %s" "$hostname"
    else
      printf "%s" "$hostname"
    fi
  fi
}
s_localip()   { [ $SHOW_LOCAL_IP -eq 1 ] && local_ip; }
s_container() { [ $SHOW_CONTAINER -eq 1 ] && in_container && printf " container"; }
s_dir()       {
  if [ $SHOW_DIR -eq 1 ]; then
    local dir; dir="$(basename_fast "$CWD")"
    # Directory substitutions matching your Starship config
    case "$dir" in
      "Code") printf "󰲋 " ;;
      "Desktop") printf " " ;;
      "Documents") printf "󰈙 " ;;
      "Downloads") printf " " ;;
      "Music") printf " " ;;
      "Pictures") printf " " ;;
      "Videos") printf " " ;;
      *) printf "%s" "$dir" ;;
    esac
  fi
}
s_git() {
  if [ $SHOW_GIT -eq 1 ]; then
    local br status_info
    br="$(git_branch)"
    if [ -n "$br" ]; then
      status_info="$(git_status_info)"
      # Format like Starship: [ branch  status ]
      printf " %s" "$br"
      [ -n "$status_info" ] && printf " %s" "$status_info"
    fi
  fi
}
s_langs()     { lang_badges; }
s_docker()    { [ $SHOW_DOCKER -eq 1 ] && docker_context; }
s_claude()    { claude_info; }
s_time()      { [ $SHOW_TIME -eq 1 ] && date '+%H:%M'; }
s_cost()      {
  if [ $SHOW_COST -eq 1 ]; then
    local cost; cost="$(get_cost)"
    if [ -n "$cost" ] && [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
      printf "\$%.3f" "$cost"
    fi
  fi
}
s_model()     {
  if [ $SHOW_MODEL -eq 1 ]; then
    local model; model="$(get_model_name)"
    [ -n "$model" ] && printf "%s" "$model"
  fi
}
s_nix_shell() {
  if [ $SHOW_NIX_SHELL -eq 1 ]; then
    if [ -n "$IN_NIX_SHELL" ]; then
      printf "❄ %s" "${name:-nix-shell}"
    elif [ -n "$NIX_PROFILES" ]; then
      printf "❄ nix"
    fi
  fi
}
s_duration()  {
  if [ $SHOW_DURATION -eq 1 ]; then
    local duration; duration="$(get_duration)"
    if [ -n "$duration" ] && [ "$duration" != "0" ] && [ "$duration" != "null" ]; then
      local dur_sec; dur_sec="$((duration / 1000))"
      printf "%ss" "$dur_sec"
    fi
  fi
}
s_hook_event() {
  if [ $SHOW_HOOK_EVENT -eq 1 ]; then
    local event; event="$(get_hook_event)"
    [ -n "$event" ] && printf "🪝 %s" "$event"
  fi
}
s_session()   {
  if [ $SHOW_SESSION -eq 1 ]; then
    local session; session="$(get_session_id)"
    if [ -n "$session" ]; then
      local short_session; short_session="$(printf '%s' "$session" | head -c 8)"
      printf "#%s" "$short_session"
    fi
  fi
}
s_output_style() {
  if [ $SHOW_OUTPUT_STYLE -eq 1 ]; then
    local style; style="$(get_output_style)"
    [ -n "$style" ] && printf "📝 %s" "$style"
  fi
}

# Build powerline segments with background colors (matching Starship format)
left_block=""

# Segment 1: OS, User, Host, IP, Container (mauve background)
seg1=""
mod_os="$(s_os)";           [ -n "$mod_os" ] && seg1+="$mod_os"
mod_user="$(s_user)";       [ -n "$mod_user" ] && seg1+=" $mod_user"
mod_host="$(s_host)";       [ -n "$mod_host" ] && seg1+="@$mod_host"
mod_ip="$(s_localip)";      [ -n "$mod_ip" ] && seg1+=" $mod_ip"
mod_ct="$(s_container)";    [ -n "$mod_ct" ] && seg1+=" [$mod_ct]"
if [ -n "$seg1" ]; then
  left_block+="${BASE0E}${SEP_LEFT}${FG_RESET}${BG_BASE0E}${BASE00}$seg1${FG_RESET}"
fi

# Segment 2: Directory (lavender background) - Always show
seg2=""
mod_dir="$(s_dir)"; [ -n "$mod_dir" ] && seg2+="$mod_dir"
# Always show segment 2, even if empty
if [ -n "$left_block" ]; then
  left_block+="${BG_BASE07}${BASE0E}${SEP_RIGHT}${FG_RESET}"
else
  left_block+="${BASE07}${SEP_LEFT}${FG_RESET}"
fi
if [ -n "$seg2" ]; then
  left_block+="${BG_BASE07}${BASE00} $seg2 ${FG_RESET}"
else
  left_block+="${BG_BASE07}${BASE00} ${FG_RESET}"
fi

# Segment 3: Nix Shell (text background)
seg3=""
mod_nix_shell="$(s_nix_shell)"; [ -n "$mod_nix_shell" ] && seg3+="$mod_nix_shell"
if [ -n "$seg3" ]; then
  # Transition from lavender to text (or start with text)
  if [ -n "$left_block" ]; then
    left_block+="${BG_BASE05}${BASE07}${SEP_RIGHT}${FG_RESET}"
  else
    left_block+="${BASE05}${SEP_LEFT}${FG_RESET}"
  fi
  left_block+="${BG_BASE05}${BASE00} $seg3 ${FG_RESET}"
fi

# Segment 4: Git (flamingo background)
seg4=""
mod_git="$(s_git)"; [ -n "$mod_git" ] && seg4+="$mod_git"
if [ -n "$seg4" ]; then
  # Transition from text to flamingo (or start with flamingo)
  if [ -n "$left_block" ]; then
    left_block+="${BG_BASE0F}${BASE05}${SEP_RIGHT}${FG_RESET}"
  else
    left_block+="${BASE0F}${SEP_LEFT}${FG_RESET}"
  fi
  left_block+="${BG_BASE0F}${BASE00}$seg4 ${FG_RESET}"
fi

# Segment 5: Languages (rosewater background) - Always show
seg5=""
mod_langs="$(s_langs)"; [ -n "$mod_langs" ] && seg5+="$mod_langs"
# Always show segment 5, even if empty
if [ -n "$left_block" ]; then
  left_block+="${BG_BASE06}${BASE0F}${SEP_RIGHT}${FG_RESET}"
else
  left_block+="${BASE06}${SEP_LEFT}${FG_RESET}"
fi
if [ -n "$seg5" ]; then
  left_block+="${BG_BASE06}${BASE00} $seg5 ${FG_RESET}"
else
  left_block+="${BG_BASE06}${BASE00} ${FG_RESET}"
fi

# Segment 6: Docker/Claude/New Modules (continue rosewater background)
seg6=""
mod_docker="$(s_docker)";     [ -n "$mod_docker" ] && seg6+="$mod_docker"
mod_claude="$(s_claude)";     [ -n "$mod_claude" ] && seg6+="${seg6:+ }$mod_claude"
mod_hook="$(s_hook_event)";   [ -n "$mod_hook" ] && seg6+="${seg6:+ }$mod_hook"
mod_output_style="$(s_output_style)"; [ -n "$mod_output_style" ] && seg6+="${seg6:+ }$mod_output_style"
if [ -n "$seg6" ]; then
  # Continue or start with rosewater background
  if [ -n "$left_block" ]; then
    # Continue with rosewater background
    left_block+="${BG_BASE06}${BASE00} $seg6 ${FG_RESET}"
  else
    left_block+="${BASE06}${SEP_LEFT}${FG_RESET}${BG_BASE06}${BASE00} $seg6 ${FG_RESET}"
  fi
fi

# End the powerline
if [ -n "$left_block" ]; then
  left_block+="${BASE06}${SEP_RIGHT}${FG_RESET}"
fi

# Right block with time (mauve background to match Starship)
right_block=""
mod_time="$(s_time)"
if [ -n "$mod_time" ]; then
  right_block+="${BASE0E}${SEP_LEFT}${FG_RESET}${BG_BASE0E}${BASE00} $mod_time ${FG_RESET}${BASE0E}${SEP_RIGHT}${FG_RESET}"
fi

# Output single line (Claude uses only the first line of stdout)
# We can't truly right-align, so we add a neutral spacer in between only if there's a right block.
if [ -n "$right_block" ]; then
  printf "%b%s%b\n" "$left_block" "$(spacer)" "$right_block"
else
  printf "%b\n" "$left_block"
fi
