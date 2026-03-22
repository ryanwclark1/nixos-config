#!/usr/bin/env bash
# qs — Unified CLI for the Quickshell panel
# Routes subcommands to existing qs-* scripts and IPC calls.
set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: qs <command> [args...]

Surface Control:
  toggle <id> [screen]  Toggle a panel/popup (audioMenu, launcher, etc.)
  open <id> [screen]    Open a panel/popup
  close                 Close all surfaces
  panic                 Emergency close all (surfaces + launcher + overview)
  reload                Reload configuration
  alt-tab               Show the alt-tab switcher

Media & Capture:
  screenshot [args]     Take screenshots (area, screen, fullscreen)
  ocr [args]            Optical character recognition
  tts [args]            Text-to-speech

AI:
  ai [args]             AI prompt (one-shot)
  ai-stream [args]      Streaming AI chat
  model-usage [args]    AI model usage statistics

Network & System:
  network [args]        Network management
  wallpaper [args]      Wallpaper management
  wallpaper-thumb [args]  Generate WebP grid thumbnail (source, dest.webp)
  keybinds [args]       Keybinding management
  bookmarks [args]      Browser bookmarks
  run [args]            Run commands via runner

Search:
  bang-sync [args]      Sync DuckDuckGo bangs
  bang-search [args]    Search with bang shortcuts

Diagnostics:
  health [args]         Health check
  plugin [args]         Plugin diagnostics
  rofi [args]           Rofi integration

Options:
  help, --help, -h      Show this help message
  version, --version    Show version info

Surface IDs: audioMenu, bluetoothMenu, networkMenu, vpnMenu, weatherMenu,
  batteryMenu, musicMenu, clipboardMenu, recordingMenu, systemStatsMenu,
  printerMenu, privacyMenu, sshMenu, dateTimeMenu, marketMenu,
  modelUsageMenu, screenshotMenu, cavaPopup,
  notifCenter, controlCenter, notepad, aiChat, commandPalette,
  powerMenu, colorPicker, displayConfig, fileBrowser, systemMonitor,
  wallhavenBrowser, launcher, overview

Screen targeting: Use "focused" for the currently focused screen,
  or a specific output name (e.g., "eDP-1", "HDMI-A-1").
HELP
}

show_version() {
  echo "qs (Quickshell Panel CLI) 1.0.0"
}

case "${1:-help}" in
  # ── Surface Control ──────────────────────────
  toggle)
    shift
    exec quickshell ipc call Shell toggleSurface "$@"
    ;;
  open)
    shift
    exec quickshell ipc call Shell openSurface "$@"
    ;;
  close)
    exec quickshell ipc call Shell closeAllSurfaces
    ;;
  panic)
    exec quickshell ipc call Shell panicClose
    ;;
  reload)
    exec quickshell ipc call Shell reloadConfig
    ;;
  alt-tab)
    exec quickshell ipc call Shell showAltTab
    ;;

  # ── Media & Capture ──────────────────────────
  screenshot)
    shift
    exec qs-screenshot "$@"
    ;;
  ocr)
    shift
    exec qs-ocr "$@"
    ;;
  tts)
    shift
    exec qs-tts-speak "$@"
    ;;

  # ── AI ───────────────────────────────────────
  ai)
    shift
    exec qs-ai "$@"
    ;;
  ai-stream)
    shift
    exec qs-ai-stream "$@"
    ;;
  model-usage)
    shift
    exec qs-model-usage "$@"
    ;;

  # ── Network & System ─────────────────────────
  network)
    shift
    exec qs-network "$@"
    ;;
  wallpaper|wallpapers)
    shift
    exec qs-wallpapers "$@"
    ;;
  wallpaper-thumb)
    shift
    exec qs-wallpaper-thumb "$@"
    ;;
  keybinds)
    shift
    exec qs-keybinds "$@"
    ;;
  bookmarks)
    shift
    exec qs-bookmarks "$@"
    ;;
  run)
    shift
    exec qs-run "$@"
    ;;

  # ── Search ───────────────────────────────────
  bang-sync)
    shift
    exec qs-bang-sync "$@"
    ;;
  bang-search)
    shift
    exec qs-bang-search "$@"
    ;;

  # ── Diagnostics ──────────────────────────────
  health)
    shift
    exec qs-health-check "$@"
    ;;
  plugin)
    shift
    exec qs-plugin-doctor "$@"
    ;;
  rofi)
    shift
    exec qs-rofi "$@"
    ;;

  # ── Meta ─────────────────────────────────────
  help|--help|-h)
    show_help
    ;;
  version|--version|-v)
    show_version
    ;;
  *)
    echo "qs: unknown command '$1'" >&2
    echo "Run 'qs help' for usage information." >&2
    exit 1
    ;;
esac
