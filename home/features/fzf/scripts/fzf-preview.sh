#!/usr/bin/env bash
# fzf-universal-preview
#
# One previewer to rule them all:
# - Directories: eza --tree (or ls/tree fallback)
# - Text: bat/batcat with line numbers & optional highlight (:LINENO), sed fallback
# - Images: Kitty/Ghostty icat > chafa (Sixel) > iTerm2 imgcat
# - Binary/unknown: `file` summary + hex/ascii (hexdump/xxd/od)
#
# Usage:
#   fzf ... --preview 'fzf-universal-preview {}'
# You can also pass "path:LINENO[:IGN]" to center-highlight a line for text files.
#
# Notes:
# - Honors FZF_PREVIEW_COLUMNS/FZF_PREVIEW_LINES for image sizing
# - Avoids bottom-row Sixel scroll glitch (fzf#2544)
# - Graceful fallbacks if dependencies are missing

set -u  # (No -e: we want graceful fallbacks; no -o pipefail for the same reason)

# --- Args & ~ expansion -------------------------------------------------------

if [[ $# -ne 1 ]]; then
  >&2 echo "usage: $0 FILENAME[:LINENO][:IGNORED]"
  exit 1
fi

raw_input=$1
file=${raw_input/#\~\//$HOME/}
center=0

# If the path isn't readable as-is, try to peel off ":LINENO[:...]" suffixes.
if [[ ! -r $file ]]; then
  if [[ $file =~ ^(.+):([0-9]+)\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
    file=${BASH_REMATCH[1]}
    center=${BASH_REMATCH[2]}
  elif [[ $file =~ ^(.+):([0-9]+):[0-9]+\ *$ ]] && [[ -r ${BASH_REMATCH[1]} ]]; then
    file=${BASH_REMATCH[1]}
    center=${BASH_REMATCH[2]}
  fi
fi

# --- Helpers ------------------------------------------------------------------

have() { command -v "$1" >/dev/null 2>&1; }

bat_cmd() {
  if have batcat; then echo "batcat"; elif have bat; then echo "bat"; else echo ""; fi
}

term_dim() {
  # Echo "COLUMNSxLINES" best-effort (prefer FZF-provided, fall back to stty)
  local dim
  dim="${FZF_PREVIEW_COLUMNS:-}x${FZF_PREVIEW_LINES:-}"
  if [[ $dim == x ]]; then
    # Try TTY (fzf preview runs attached to a TTY)
    dim=$(stty size < /dev/tty 2>/dev/null | awk '{print $2 "x" $1}')
    [[ -z "$dim" ]] && dim="80x24"
  else
    # Workaround: if preview hits bottom row and not Kitty, trim 1 line for Sixel
    if [[ -z ${KITTY_WINDOW_ID:-} ]] \
       && (( ${FZF_PREVIEW_TOP:-0} + ${FZF_PREVIEW_LINES:-0} == $(stty size < /dev/tty 2>/dev/null | awk '{print $1}') )); then
      dim="${FZF_PREVIEW_COLUMNS}x$((FZF_PREVIEW_LINES-1))"
    fi
  fi
  echo "$dim"
}

mime_of() {
  # Fast, quiet mime type
  file --mime-type -Lb -- "$1" 2>/dev/null || true
}

full_mime_desc() {
  file --brief --dereference --mime -- "$1" 2>/dev/null || true
}

show_tree() {
  local path=$1
  if have eza; then
    eza --tree --level=2 --color=always -- "$path" | head -200
  else
    # Try colorized ls; if it fails, try tree (not always installed)
    ls -la --color=always -- "$path" 2>/dev/null || tree -L 2 -- "$path" 2>/dev/null
  fi
}

show_text() {
  local path=$1 hl=${2:-0}
  local bat
  bat=$(bat_cmd)
  if [[ -n "$bat" ]]; then
    # Up to 500 lines by default to keep previews snappy
    "$bat" --style="${BAT_STYLE:-numbers}" --color=always --pager=never \
           ${hl:+--highlight-line="$hl"} --line-range=:500 -- "$path"
  else
    # sed fallback (1..500)
    sed -n '1,500p' -- "$path"
  fi
}

show_binary() {
  local path=$1
  full_mime_desc "$path" || true
  if have hexdump; then
    hexdump -C -n 1024 -- "$path"
  elif have xxd; then
    xxd -g 1 -l 1024 -- "$path"
  else
    head -c 1024 -- "$path" | od -An -tx1 -v
  fi
}

show_image() {
  local path=$1
  local dim; dim=$(term_dim)

  # 1) Kitty/Ghostty icat via kitten
  if { [[ -n ${KITTY_WINDOW_ID:-} ]] || [[ -n ${GHOSTTY_RESOURCES_DIR:-} ]]; } && have kitten; then
    # Use memory transfer for speed; scrub trailing reset line (fzf scroll quirk)
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place="$dim@0x0" -- "$path" \
      | sed '$d' | sed $'$s/$/\e[m/'
    return
  fi

  # 2) chafa (Sixel/ANSI graphics)
  if have chafa; then
    chafa -s "$dim" -- "$path"
    echo  # ensure newline so multiple images don’t stack weirdly
    return
  fi

  # 3) iTerm2 imgcat
  if have imgcat; then
    local width="${dim%%x*}" height="${dim##*x}"
    imgcat -W "$width" -H "$height" -- "$path"
    return
  fi

  # 4) Fallback: just describe the file
  full_mime_desc "$path"
}

is_text_mime() {
  case "$1" in
    text/*|application/json|application/xml|application/x-sh|application/x-yaml|application/yaml)
      return 0 ;;
    *) return 1 ;;
  esac
}

# --- Main routing -------------------------------------------------------------

if [[ -z "${file:-}" ]]; then
  echo "No input"
  exit 0
fi

# Directories first
if [[ -d "$file" ]]; then
  show_tree "$file"
  exit 0
fi

# If it's not a file (broken link, missing, etc.), report what we can
if [[ ! -f "$file" ]]; then
  full_mime_desc "$file"
  exit 0
fi

# Decide by mime
mime="$(mime_of "$file")"

# Images
if [[ "$mime" == image/* ]]; then
  show_image "$file"
  exit 0
fi

# Text-ish
if is_text_mime "$mime"; then
  show_text "$file" "$center"
  exit 0
fi

# If `file --mime` tagged it as binary/charset=binary, treat as binary
brief="$(full_mime_desc "$file")"
if [[ "$brief" =~ (=|charset=)binary ]] || [[ "$mime" == application/octet-stream ]]; then
  show_binary "$file"
  exit 0
fi

# Otherwise, try bat as text; if it renders poorly, user still sees something
show_text "$file" "$center"
