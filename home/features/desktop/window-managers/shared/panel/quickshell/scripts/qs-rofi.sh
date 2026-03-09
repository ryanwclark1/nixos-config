#!/usr/bin/env bash
# qs-rofi.sh - Quickshell based Rofi/Dmenu replacement

MODE="${1:-drun}"

case "$MODE" in
  "-show" | "show")
    shift
    SUBMODE="${1:-drun}"
    case "$SUBMODE" in
      "drun")
        quickshell ipc call Launcher openDrun
        ;;
      "window")
        quickshell ipc call Launcher openWindow
        ;;
      "run")
        quickshell ipc call Launcher openRun
        ;;
      "emoji")
        quickshell ipc call Launcher openEmoji
        ;;
      "calc")
        quickshell ipc call Launcher openCalc
        ;;
      "clip")
        quickshell ipc call Launcher openClip
        ;;
      "web")
        quickshell ipc call Launcher openWeb
        ;;
      "system")
        quickshell ipc call Launcher openSystem
        ;;
      "nixos")
        quickshell ipc call Launcher openNixos
        ;;
      "files")
        quickshell ipc call Launcher openFiles
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
    
    # Convert to JSON array string
    json_items=$(printf '%s\n' "${items[@]}" | jq -R . | jq -s -c .)
    
    # Setup FIFO
    fifo_path="/tmp/qs-dmenu-result"
    [ -p "$fifo_path" ] || mkfifo "$fifo_path"
    
    # Send to Quickshell
    quickshell ipc call Launcher openDmenu "$json_items"
    
    # Wait for result and output to stdout
    cat "$fifo_path"
    rm "$fifo_path"
    ;;
  *)
    # Default to drun if no arguments
    quickshell ipc call Launcher openDrun
    ;;
esac
