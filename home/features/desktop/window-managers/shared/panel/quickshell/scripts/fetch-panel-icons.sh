#!/usr/bin/env bash
# fetch-panel-icons.sh — Download SVG icons from Fluent UI System Icons and Phosphor
# Source: microsoft/fluentui-system-icons (MIT), phosphor-icons/core (MIT)
# Usage: ./scripts/fetch-panel-icons.sh [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ICONS_DIR="$SCRIPT_DIR/../src/assets/icons"
FLUENT_DIR="$ICONS_DIR/fluent"
BRANDS_DIR="$ICONS_DIR/brands"

FLUENT_BASE="https://raw.githubusercontent.com/microsoft/fluentui-system-icons/main/assets"
PHOSPHOR_BASE="https://raw.githubusercontent.com/phosphor-icons/core/main/assets/regular"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

downloaded=0
skipped=0
failed=0

# fetch_fluent <FolderName> <size> <Regular|Filled> <output-name.svg>
# URL: assets/{FolderName}/SVG/ic_fluent_{folder_snake}_{size}_{variant}.svg
fetch_fluent() {
    local folder_name="$1"
    local size="${2:-24}"
    local variant="${3:-Regular}"
    local out_name="$4"
    local dest="$FLUENT_DIR/$out_name"

    if [[ -f "$dest" ]]; then
        ((skipped++)) || true
        return 0
    fi

    local url_folder
    url_folder=$(echo "$folder_name" | sed 's/ /%20/g')
    local snake
    snake=$(echo "$folder_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    local var_lower="${variant,,}"
    local url="${FLUENT_BASE}/${url_folder}/SVG/ic_fluent_${snake}_${size}_${var_lower}.svg"

    if $DRY_RUN; then
        echo "[dry-run] $out_name <- $url"
        return 0
    fi

    if curl -fsSL --retry 2 --max-time 10 -o "$dest" "$url" 2>/dev/null; then
        echo "[ok] $out_name"
        ((downloaded++)) || true
    else
        echo "[FAIL] $out_name  ($url)"
        ((failed++)) || true
    fi
}

fetch_phosphor() {
    local icon_name="$1"
    local out_name="$2"
    local dest="$FLUENT_DIR/$out_name"

    if [[ -f "$dest" ]]; then
        ((skipped++)) || true
        return 0
    fi

    local url="${PHOSPHOR_BASE}/${icon_name}.svg"

    if $DRY_RUN; then
        echo "[dry-run] $out_name <- $url (phosphor)"
        return 0
    fi

    if curl -fsSL --retry 2 --max-time 10 -o "$dest" "$url" 2>/dev/null; then
        echo "[ok] $out_name (phosphor)"
        ((downloaded++)) || true
    else
        echo "[FAIL] $out_name  ($url)"
        ((failed++)) || true
    fi
}

fetch_brand() {
    local url="$1"
    local out_name="$2"
    local dest="$BRANDS_DIR/$out_name"

    if [[ -f "$dest" ]]; then
        ((skipped++)) || true
        return 0
    fi

    if $DRY_RUN; then
        echo "[dry-run] brands/$out_name <- $url"
        return 0
    fi

    if curl -fsSL --retry 2 --max-time 10 -o "$dest" "$url" 2>/dev/null; then
        echo "[ok] brands/$out_name"
        ((downloaded++)) || true
    else
        echo "[FAIL] brands/$out_name  ($url)"
        ((failed++)) || true
    fi
}

mkdir -p "$FLUENT_DIR" "$BRANDS_DIR"

echo "=== Fetching Fluent UI System Icons (MIT) ==="
echo ""

# --- System ---
echo "-- System --"
fetch_fluent "Sleep"                   24 Regular "power-sleep.svg"
fetch_fluent "Sleep"                   24 Filled  "power-sleep-filled.svg"
fetch_fluent "Arrow Counterclockwise"  24 Regular "restart.svg"
fetch_fluent "Arrow Counterclockwise"  24 Filled  "restart-filled.svg"
fetch_fluent "Sign Out"                24 Regular "sign-out.svg"
fetch_fluent "Sign Out"                24 Filled  "sign-out-filled.svg"
fetch_fluent "Laptop"                  24 Regular "laptop.svg"
fetch_fluent "Laptop"                  24 Filled  "laptop-filled.svg"

# --- Files ---
echo "-- Files --"
fetch_fluent "Folder"                  24 Regular "folder.svg"
fetch_fluent "Folder"                  24 Filled  "folder-filled.svg"
fetch_fluent "Folder Open"             24 Regular "folder-open.svg"
fetch_fluent "Folder Open"             24 Filled  "folder-open-filled.svg"
fetch_fluent "Document"                24 Regular "document.svg"
fetch_fluent "Document"                24 Filled  "document-filled.svg"
fetch_fluent "Save"                    24 Regular "save.svg"
fetch_fluent "Save"                    24 Filled  "save-filled.svg"
fetch_fluent "Copy"                    24 Regular "copy.svg"
fetch_fluent "Copy"                    24 Filled  "copy-filled.svg"
fetch_fluent "Clipboard Paste"         24 Regular "paste.svg"
fetch_fluent "Clipboard Paste"         24 Filled  "paste-filled.svg"
fetch_fluent "Delete"                  24 Regular "delete.svg"
fetch_fluent "Delete"                  24 Filled  "delete-filled.svg"
fetch_fluent "Rename"                  24 Regular "rename.svg"
fetch_fluent "Rename"                  24 Filled  "rename-filled.svg"

# --- Dev/Code ---
echo "-- Dev/Code --"
fetch_fluent "Code"                    24 Regular "code.svg"
fetch_fluent "Code"                    24 Filled  "code-filled.svg"
fetch_fluent "Window Dev Tools"        24 Regular "terminal.svg"
fetch_fluent "Window Dev Tools"        24 Filled  "terminal-filled.svg"
fetch_fluent "Bug"                     24 Regular "bug.svg"
fetch_fluent "Bug"                     24 Filled  "bug-filled.svg"
fetch_fluent "Branch Fork"             24 Regular "git-branch.svg"
fetch_fluent "Branch Fork"             24 Filled  "git-branch-filled.svg"
fetch_fluent "Branch"                  24 Regular "git-commit.svg"
fetch_fluent "Branch"                  24 Filled  "git-commit-filled.svg"
fetch_fluent "Developer Board"         24 Regular "developer-board.svg"
fetch_fluent "Developer Board"         24 Filled  "developer-board-filled.svg"

# --- Navigation ---
echo "-- Navigation --"
fetch_fluent "Home"                    24 Regular "home.svg"
fetch_fluent "Home"                    24 Filled  "home-filled.svg"
fetch_fluent "Link"                    24 Regular "link.svg"
fetch_fluent "Link"                    24 Filled  "link-filled.svg"
fetch_fluent "Filter"                  24 Regular "filter.svg"
fetch_fluent "Filter"                  24 Filled  "filter-filled.svg"
fetch_fluent "Arrow Sort"              24 Regular "sort.svg"
fetch_fluent "Arrow Sort"              24 Filled  "sort-filled.svg"

# --- Media ---
echo "-- Media --"
fetch_fluent "Arrow Shuffle"           24 Regular "shuffle.svg"
fetch_fluent "Arrow Shuffle"           24 Filled  "shuffle-filled.svg"
fetch_fluent "Arrow Repeat All"        24 Regular "repeat.svg"
fetch_fluent "Arrow Repeat All"        24 Filled  "repeat-filled.svg"
fetch_fluent "Full Screen Maximize"    24 Regular "fullscreen.svg"
fetch_fluent "Full Screen Maximize"    24 Filled  "fullscreen-filled.svg"
fetch_fluent "Picture In Picture"      24 Regular "pip.svg"
fetch_fluent "Picture In Picture"      24 Filled  "pip-filled.svg"

# --- Network ---
echo "-- Network --"
fetch_fluent "Arrow Download"          24 Regular "download.svg"
fetch_fluent "Arrow Download"          24 Filled  "download-filled.svg"
fetch_fluent "Arrow Upload"            24 Regular "upload.svg"
fetch_fluent "Arrow Upload"            24 Filled  "upload-filled.svg"
fetch_fluent "Cloud"                   24 Regular "cloud.svg"
fetch_fluent "Cloud"                   24 Filled  "cloud-filled.svg"

# --- Communication ---
echo "-- Communication --"
fetch_fluent "Chat"                    24 Regular "chat.svg"
fetch_fluent "Chat"                    24 Filled  "chat-filled.svg"
fetch_fluent "Send"                    24 Regular "send.svg"
fetch_fluent "Send"                    24 Filled  "send-filled.svg"
fetch_fluent "Mail"                    24 Regular "mail.svg"
fetch_fluent "Mail"                    24 Filled  "mail-filled.svg"

# --- Hardware ---
echo "-- Hardware --"
fetch_fluent "Hard Drive"              24 Regular "hard-drive.svg"
fetch_fluent "Hard Drive"              24 Filled  "hard-drive-filled.svg"
fetch_fluent "Board"                   24 Regular "board.svg"
fetch_fluent "Board"                   24 Filled  "board-filled.svg"
fetch_fluent "Print"                   24 Regular "print.svg"
fetch_fluent "Print"                   24 Filled  "print-filled.svg"
fetch_fluent "Usb Stick"               24 Regular "usb.svg"
fetch_fluent "Usb Stick"               24 Filled  "usb-filled.svg"
fetch_fluent "Server"                  24 Regular "server-2.svg"
fetch_fluent "Server"                  24 Filled  "server-2-filled.svg"

# --- Status ---
echo "-- Status --"
fetch_fluent "Info"                    24 Regular "info.svg"
fetch_fluent "Info"                    24 Filled  "info-filled.svg"
fetch_fluent "Warning"                 24 Regular "warning.svg"
fetch_fluent "Warning"                 24 Filled  "warning-filled.svg"
fetch_fluent "Error Circle"            24 Regular "error.svg"
fetch_fluent "Error Circle"            24 Filled  "error-filled.svg"
fetch_fluent "Checkmark Circle"        24 Regular "success.svg"
fetch_fluent "Checkmark Circle"        24 Filled  "success-filled.svg"
fetch_fluent "Clock"                   24 Regular "clock.svg"
fetch_fluent "Clock"                   24 Filled  "clock-filled.svg"
fetch_fluent "Timer"                   24 Regular "timer.svg"
fetch_fluent "Timer"                   24 Filled  "timer-filled.svg"

# --- Actions ---
echo "-- Actions --"
fetch_fluent "Edit"                    24 Regular "edit.svg"
fetch_fluent "Edit"                    24 Filled  "edit-filled.svg"
fetch_fluent "Archive"                 24 Regular "archive.svg"
fetch_fluent "Archive"                 24 Filled  "archive-filled.svg"
fetch_fluent "Share"                   24 Regular "share.svg"
fetch_fluent "Share"                   24 Filled  "share-filled.svg"
fetch_fluent "Bookmark"                24 Regular "bookmark.svg"
fetch_fluent "Bookmark"                24 Filled  "bookmark-filled.svg"
fetch_fluent "Star"                    24 Regular "star.svg"
fetch_fluent "Star"                    24 Filled  "star-filled.svg"
fetch_fluent "Heart"                   24 Regular "heart.svg"
fetch_fluent "Heart"                   24 Filled  "heart-filled.svg"

# --- Misc ---
echo "-- Misc --"
fetch_fluent "Color"                   24 Regular "color-palette.svg"
fetch_fluent "Color"                   24 Filled  "color-palette-filled.svg"
fetch_fluent "Paint Brush"             24 Regular "paint-brush.svg"
fetch_fluent "Paint Brush"             24 Filled  "paint-brush-filled.svg"
fetch_fluent "Ruler"                   24 Regular "ruler.svg"
fetch_fluent "Ruler"                   24 Filled  "ruler-filled.svg"
fetch_fluent "Compass Northwest"       24 Regular "compass.svg"
fetch_fluent "Compass Northwest"       24 Filled  "compass-filled.svg"
fetch_fluent "Lightbulb"               24 Regular "lightbulb.svg"
fetch_fluent "Lightbulb"               24 Filled  "lightbulb-filled.svg"
fetch_fluent "Key"                     24 Regular "key.svg"
fetch_fluent "Key"                     24 Filled  "key-filled.svg"
fetch_fluent "Fingerprint"             24 Regular "fingerprint.svg"
fetch_fluent "Fingerprint"             24 Filled  "fingerprint-filled.svg"

echo ""
echo "=== Fetching Phosphor gap-fills (MIT) ==="
fetch_phosphor "timer"                 "pomodoro.svg"

echo ""
echo "=== Fetching brand icons ==="
fetch_brand "https://cdn.simpleicons.org/anthropic/white"  "anthropic-symbolic.svg"
fetch_brand "https://cdn.simpleicons.org/groq/white"       "groq-symbolic.svg"
fetch_brand "https://cdn.simpleicons.org/perplexity/white"  "perplexity-symbolic.svg"
fetch_brand "https://cdn.simpleicons.org/wayland/white"     "wayland-symbolic.svg"
fetch_brand "https://cdn.simpleicons.org/pipewire/white"    "pipewire-symbolic.svg"
fetch_brand "https://cdn.simpleicons.org/systemd/white"     "systemd-symbolic.svg"

echo ""
echo "=== Done ==="
echo "Downloaded: $downloaded | Skipped (existing): $skipped | Failed: $failed"
