{ pkgs, lib }:

pkgs.writeShellScriptBin "mcp-server-playwright-nixos" ''
  #!/usr/bin/env bash
  set -euo pipefail

  if [ -n "''${PLAYWRIGHT_BROWSERS_PATH:-}" ]; then
    export PLAYWRIGHT_BROWSERS_PATH
  elif [ -d "${lib.getLib pkgs.playwright.browsers}" ]; then
    export PLAYWRIGHT_BROWSERS_PATH="${lib.getLib pkgs.playwright.browsers}"
  fi

  if [ -z "''${PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH:-}" ]; then
    for candidate in chromium chromium-browser google-chrome-stable google-chrome; do
      if target=$(command -v "$candidate" 2>/dev/null); then
        export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="$target"
        break
      fi
    done
  fi

  export PATH="${
    lib.makeBinPath (
      with pkgs;
      [
        coreutils
      ]
    )
  }:$PATH"

  exec ${pkgs.playwright-mcp}/bin/mcp-server-playwright "$@"
''
