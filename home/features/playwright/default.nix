{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages =
    let
      playwrightCli = pkgs.writeShellScriptBin "playwright" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Ensure Playwright sees the Nix-provided browser bundle unless the
        # caller has overridden it explicitly.
        export PLAYWRIGHT_BROWSERS_PATH="''${PLAYWRIGHT_BROWSERS_PATH:-${lib.getLib pkgs.playwright.browsers}}"

        exec ${pkgs.nodejs}/bin/node ${pkgs.playwright}/cli.js "$@"
      '';
    in
    with pkgs;
    [
      # Upstream Playwright CLI assets. nixpkgs currently exposes the package
      # contents but not a usable `playwright` executable in the profile.
      playwright
      playwrightCli

      # Browser bundle used by the CLI on NixOS.
      # Includes Chromium, Chromium Headless Shell, Firefox, WebKit, and FFmpeg.
      playwright.browsers
    ];

  # Environment variables for Playwright to find browsers
  # This ensures Playwright can locate all browsers and tools in NixOS
  home.sessionVariables = {
    # Point to Playwright's bundled browsers and tools:
    # - Chromium (default browser)
    # - Chromium Headless Shell (for headless automation)
    # - Firefox (for cross-browser testing)
    # - WebKit (for Safari-like testing)
    # - FFmpeg (for video recording and processing)
    # This is the most reliable way to ensure Playwright works in NixOS
    PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
  };
}
