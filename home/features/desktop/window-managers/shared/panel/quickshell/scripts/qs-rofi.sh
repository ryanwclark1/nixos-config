#!/usr/bin/env bash
# qs-rofi.sh - Quickshell based Rofi/Dmenu replacement

MODE="${1:-drun}"

case "$MODE" in
  "-show" | "show")
    shift
    SUBMODE="${1:-drun}"
    case "$SUBMODE" in
      "drun")
        quickshell --ipc-eval "launcher.openDrun()"
        ;;
      "window")
        quickshell --ipc-eval "launcher.openWindow()"
        ;;
      "run")
        quickshell --ipc-eval "launcher.openRun()"
        ;;
      "emoji")
        quickshell --ipc-eval "launcher.openEmoji()"
        ;;
      "calc")
        quickshell --ipc-eval "launcher.openCalc()"
        ;;
      "clip")
        quickshell --ipc-eval "launcher.openClip()"
        ;;
      "web")
        quickshell --ipc-eval "launcher.openWeb()"
        ;;
      "system")
        quickshell --ipc-eval "launcher.openSystem()"
        ;;
      *)
        echo "Unknown mode: $SUBMODE"
        exit 1
        ;;
    esac
    ;;
  "-dmenu" | "dmenu")
    # Read from stdin
    items=()
    while read -r line; do
      items+=("$line")
    done
    
    # Convert to JSON array
    json_items=$(printf '%s\n' "${items[@]}" | jq -R . | jq -s .)
    json_payload=$(printf '%s' "$json_items" | jq -Rs .)
    
    # Setup FIFO
    fifo_path="/tmp/qs-dmenu-result"
    [ -p "$fifo_path" ] || mkfifo "$fifo_path"
    
    # Send to Quickshell
    quickshell --ipc-eval "launcher.openDmenu($json_payload)"
    
    # Wait for result and output to stdout
    cat "$fifo_path"
    rm "$fifo_path"
    ;;
  *)
    # Default to drun if no arguments
    quickshell --ipc-eval "launcher.openDrun()"
    ;;
esac
