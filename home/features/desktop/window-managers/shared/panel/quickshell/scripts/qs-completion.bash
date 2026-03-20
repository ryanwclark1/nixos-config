#!/usr/bin/env bash
# Tab completion for the `qs` CLI dispatcher.
# Source this file in .bashrc or install to /etc/bash_completion.d/

_qs_completions() {
  local cur prev commands surface_ids
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  commands="toggle open close panic reload alt-tab screenshot ocr tts ai ai-stream model-usage network wallpaper keybinds bookmarks run bang-sync bang-search health plugin rofi help version"

  surface_ids="audioMenu bluetoothMenu networkMenu vpnMenu weatherMenu batteryMenu musicMenu clipboardMenu recordingMenu systemStatsMenu printerMenu privacyMenu sshMenu dateTimeMenu marketMenu modelUsageMenu screenshotMenu cavaPopup notifCenter controlCenter notepad aiChat commandPalette powerMenu colorPicker displayConfig fileBrowser systemMonitor wallhavenBrowser launcher overview"

  case "$prev" in
    toggle|open)
      COMPREPLY=( $(compgen -W "$surface_ids" -- "$cur") )
      return
      ;;
    qs)
      COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
      return
      ;;
  esac

  # If we're at position 3+ after toggle/open, offer screen hints
  if [[ ${#COMP_WORDS[@]} -ge 4 ]] && [[ "${COMP_WORDS[1]}" == "toggle" || "${COMP_WORDS[1]}" == "open" ]]; then
    COMPREPLY=( $(compgen -W "focused" -- "$cur") )
    return
  fi

  COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
}

complete -F _qs_completions qs
