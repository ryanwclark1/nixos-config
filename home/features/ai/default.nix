{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Wrapper script for playwright-mcp that handles NixOS browser paths
  playwrightMcpWrapper = pkgs.writeShellScriptBin "mcp-server-playwright-nixos" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Playwright MCP wrapper for NixOS
    # This script ensures Playwright can find browsers in NixOS environments

    # Option 1: Use Playwright's bundled browsers (recommended for reliability)
    # The playwright.browsers package provides Chromium, Firefox, and WebKit
    if [ -n "''${PLAYWRIGHT_BROWSERS_PATH:-}" ]; then
      export PLAYWRIGHT_BROWSERS_PATH
    elif [ -d "${lib.getLib pkgs.playwright.browsers}" ]; then
      export PLAYWRIGHT_BROWSERS_PATH="${lib.getLib pkgs.playwright.browsers}"
    fi

    # Option 2: If using system Chrome/Chromium, set executable path explicitly
    # Playwright will try to find Chrome in standard locations, but in NixOS
    # browsers are in the Nix store. We can set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH
    # if we want to use the system browser instead of bundled Chromium.
    # Note: Prefer Chromium over Chrome if both are available (Chromium is more common in NixOS)
    if [ -z "''${PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH:-}" ]; then
      # Try to find browsers in PATH, preferring Chromium over Chrome
      for candidate in chromium chromium-browser google-chrome-stable google-chrome; do
        if target=$(command -v "$candidate" 2>/dev/null); then
          export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="$target"
          break
        fi
      done
    fi

    # Ensure all browser dependencies are available in PATH
    export PATH="${
      lib.makeBinPath (
        with pkgs;
        [
          coreutils
          # Add any other dependencies needed by browsers
        ]
      )
    }:$PATH"

    # Run the actual playwright-mcp server
    exec ${pkgs.playwright-mcp}/bin/mcp-server-playwright "$@"
  '';
in
{
  imports = [
    ./aichat
    ./claude
    ./crush
    ./gemini
    ./goose
    ./qwen
    ./codex
    ./opencode
    # ./ollama
  ];
  home.packages = with pkgs; [
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    playwright-mcp
    # Playwright browsers - provides bundled Chromium, Firefox, and WebKit
    # This is the most reliable way to ensure Playwright works in NixOS
    playwright.browsers
    github-mcp-server
    amp-cli
    # aider-chat-full  # Temporarily disabled due to mercantile package build failure

    # Docker for running MCP servers
    docker
    docker-compose

    # Wrapper script for NixOS compatibility
    playwrightMcpWrapper

    # Beads - issue tracker for AI-supervised coding workflows
    beads
  ];

  # Environment variables for Playwright
  # These help Playwright find browsers in NixOS
  home.sessionVariables = {
    # Point to Playwright's bundled browsers (most reliable)
    PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
  };

}
