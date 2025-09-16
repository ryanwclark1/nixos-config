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
SHOW_USER=1
SHOW_HOST=0
SHOW_LOCAL_IP=0
SHOW_CONTAINER=1
SHOW_DIR=1
SHOW_GIT=1
SHOW_LANGS=0
SHOW_DOCKER=1
SHOW_NIX=1
SHOW_TIME=0
SHOW_CLAUDE=1

# Performance: keep git checks cheap
GIT_TIMEOUT=80   # ms budget for git calls (best-effort)

# ------------- Helpers ---------------------------------------
# Read the JSON once (Claude sends session info on stdin)
INPUT="$(cat 2>/dev/null)"
# Extract workspace cwd with jq if available; fallback to $PWD
if command -v jq >/dev/null 2>&1; then
  CWD="$(printf '%s' "$INPUT" | jq -r '.workspace.current_dir // empty')"
fi
CWD="${CWD:-$PWD}"

basename_fast() { printf '%s' "${1##*/}"; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

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
  # Very fast branch check without invoking multiple processes when possible
  if [ -d ".git" ]; then
    # Detached/head read
    local head; head=$(2>/dev/null < .git/HEAD tr -d '\n')
    case "$head" in
      ref:\ refs/heads/*) printf '%s' "${head#ref: refs/heads/}"; return 0;;
    esac
  fi
  # Fallback to git (with a timeout)
  if has_cmd git; then
    ( git branch --show-current 2>/dev/null & pid=$!; \
      sleep 0.$GIT_TIMEOUT; kill -0 $pid 2>/dev/null && kill $pid 2>/dev/null; true ) >/dev/null
    git branch --show-current 2>/dev/null
  fi
}

git_dirty() {
  # Fast dirtiness check
  if has_cmd git && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Porcelain short; any output = dirty
    git status --porcelain -uno 2>/dev/null | head -n1 | wc -l | tr -d ' '
  else
    printf '0'
  fi
}

docker_context() {
  if has_cmd docker; then
    local ctx; ctx="$(docker context show 2>/dev/null)"
    [ -n "$ctx" ] && printf " %s" "$ctx"
  fi
}

nix_shell() {
  if [ -n "$IN_NIX_SHELL" ]; then
    printf ' %s' "${name:-nix-shell}"
  elif [ -n "$NIX_PROFILES" ]; then
    printf ' nix'
  fi
}

lang_badges() {
  local out=""
  # Python venv / version - matches your Starship config
  if [ -n "$VIRTUAL_ENV" ] || has_cmd python3; then
    local pyv; pyv="$(python3 -V 2>/dev/null | awk '{print $2}')"
    [ -n "$pyv" ] && out+="${out:+ }🐍${pyv}"
  fi
  # Node - matches your Starship config
  if has_cmd node; then
    local nv; nv="$(node -v 2>/dev/null)"
    [ -n "$nv" ] && out+="${out:+ }⬢${nv#v}"
  fi
  # Rust - matches your Starship config
  if has_cmd rustc; then
    local rv; rv="$(rustc --version 2>/dev/null | awk '{print $2}')"
    [ -n "$rv" ] && out+="${out:+ }🦀${rv}"
  fi
  # Go
  if has_cmd go; then
    local gv; gv="$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')"
    [ -n "$gv" ] && out+="${out:+ }🐹${gv}"
  fi
  # Deno
  if has_cmd deno; then
    local dv; dv="$(deno --version 2>/dev/null | head -n1 | awk '{print $2}')"
    [ -n "$dv" ] && out+="${out:+ }🦕${dv}"
  fi
  # Bun
  if has_cmd bun; then
    local bv; bv="$(bun --version 2>/dev/null)"
    [ -n "$bv" ] && out+="${out:+ }🥟${bv}"
  fi
  printf '%s' "$out"
}

claude_info() {
  if [ $SHOW_CLAUDE -eq 1 ] && [ -n "$INPUT" ]; then
    local claude_context=""
    # Extract model info if available
    if command -v jq >/dev/null 2>&1; then
      local model; model="$(printf '%s' "$INPUT" | jq -r '.model // empty' 2>/dev/null)"
      local session; session="$(printf '%s' "$INPUT" | jq -r '.session.id // empty' 2>/dev/null | head -c 8)"
      [ -n "$model" ] && claude_context+="$model"
      [ -n "$session" ] && claude_context+="${claude_context:+ }#$session"
    fi
    [ -n "$claude_context" ] && printf "🤖 %s" "$claude_context" || printf "🤖 Claude"
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
        # Check for specific distro - matches your Starship config
        if [ -f /etc/os-release ]; then
          . /etc/os-release
          case "$ID" in
            nixos) printf " " ;;
            arch) printf "󰣇" ;;
            ubuntu) printf "󰕈 " ;;
            fedora) printf "󰣛 " ;;
            debian) printf " " ;;
            *) printf "󰌽 " ;;
          esac
        else
          printf "󰌽 "
        fi
        ;;
      Darwin) printf "󰀵" ;;
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
      "Desktop") printf " " ;;
      "Documents") printf "󰈙 " ;;
      "Downloads") printf " " ;;
      "Music") printf " " ;;
      "Pictures") printf " " ;;
      "Videos") printf " " ;;
      *) printf "%s" "$dir" ;;
    esac
  fi
}
s_git() {
  if [ $SHOW_GIT -eq 1 ]; then
    local br dirty
    br="$(git_branch)"
    if [ -n "$br" ]; then
      dirty="$(git_dirty)"
      [ "$dirty" != "0" ] && printf " %s%s" "$br" "${FG_DIM}*${FG_RESET}" || printf " %s" "$br"
    fi
  fi
}
s_langs()     { [ $SHOW_LANGS -eq 1 ] && lang_badges; }
s_docker()    { [ $SHOW_DOCKER -eq 1 ] && docker_context; }
s_nix()       { [ $SHOW_NIX -eq 1 ] && nix_shell; }
s_claude()    { [ $SHOW_CLAUDE -eq 1 ] && claude_info; }
s_time()      { [ $SHOW_TIME -eq 1 ] && date '+%H:%M'; }

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

# Segment 2: Directory (lavender background)
mod_dir="$(s_dir)"
if [ -n "$mod_dir" ]; then
  # Transition from mauve to lavender (or start with lavender)
  if [ -n "$left_block" ]; then
    left_block+="${BG_BASE07}${BASE0E}${SEP_RIGHT}${FG_RESET}"
  else
    left_block+="${BASE07}${SEP_LEFT}${FG_RESET}"
  fi
  left_block+="${BG_BASE07}${BASE00} $mod_dir ${FG_RESET}"
fi

# Segment 3: Git (text background)
mod_git="$(s_git)"
if [ -n "$mod_git" ]; then
  # Transition from lavender to text (or start with text)
  if [ -n "$left_block" ]; then
    left_block+="${BG_BASE05}${BASE07}${SEP_RIGHT}${FG_RESET}"
  else
    left_block+="${BASE05}${SEP_LEFT}${FG_RESET}"
  fi
  left_block+="${BG_BASE05}${BASE00}$mod_git ${FG_RESET}"
fi

# Segment 4: Languages (flamingo background)
mod_langs="$(s_langs)"
if [ -n "$mod_langs" ]; then
  # Transition from text to flamingo (or start with flamingo)
  if [ -n "$left_block" ]; then
    left_block+="${BG_BASE0F}${BASE05}${SEP_RIGHT}${FG_RESET}"
  else
    left_block+="${BASE0F}${SEP_LEFT}${FG_RESET}"
  fi
  left_block+="${BG_BASE0F}${BASE00} $mod_langs ${FG_RESET}"
fi

# Segment 5: Docker/Nix/Claude (rosewater background)
seg5=""
mod_docker="$(s_docker)";   [ -n "$mod_docker" ] && seg5+="$mod_docker"
mod_nix="$(s_nix)";         [ -n "$mod_nix" ] && seg5+="$mod_nix"
mod_claude="$(s_claude)";   [ -n "$mod_claude" ] && seg5+="${seg5:+ }$mod_claude"
if [ -n "$seg5" ]; then
  # Transition from flamingo to rosewater (or start with rosewater)
  if [ -n "$left_block" ]; then
    left_block+="${BG_BASE06}${BASE0F}${SEP_RIGHT}${FG_RESET}"
  else
    left_block+="${BASE06}${SEP_LEFT}${FG_RESET}"
  fi
  left_block+="${BG_BASE06}${BASE00} $seg5 ${FG_RESET}"
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
# We can’t truly right-align, so we add a neutral spacer in between.
printf "%b%s%b\n" "$left_block" "$(spacer)" "$right_block"
