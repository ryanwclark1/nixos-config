{ config, pkgs, ... }:

{
  # Note home.shellAlias was not working when being called from other apps.
  home.packages = [
    (pkgs.google-chrome.override {
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--ozone-platform-hint=wayland"
        "--enable-features=TouchpadOverscrollHistoryNavigation"
        # Chromium crash workaround for Wayland color management on Hyprland
        "--disable-features=WaylandWpColorManagerV1"
        "--load-extension=${config.home.homeDirectory}/.local/share/omarchy/default/chromium/extensions/copy-url"
      ];
    })
    (pkgs.writeShellScriptBin "google-chrome" ''
       google-chrome-stable "$@"
    '')
    # Wrapper for google-chrome-status helper process
    # Chrome expects this helper to be available in PATH for status checks
    # This fixes the "Failed to open child process" error on NixOS
    (pkgs.writeShellScriptBin "google-chrome-status" ''
      # Find the actual Chrome binary
      CHROME_BIN="$(command -v google-chrome-stable 2>/dev/null)"

      if [ -n "$CHROME_BIN" ]; then
        # Try to find the actual status helper in Chrome's package directory
        CHROME_DIR="$(dirname "$CHROME_BIN")"
        CHROME_LIB="${CHROME_DIR}/../lib/google-chrome"

        # Check multiple possible locations for the status helper
        for STATUS_PATH in \
          "$CHROME_LIB/google-chrome-status" \
          "$CHROME_DIR/google-chrome-status" \
          "${pkgs.google-chrome}/lib/google-chrome/google-chrome-status"; do
          if [ -f "$STATUS_PATH" ] && [ -x "$STATUS_PATH" ]; then
            exec "$STATUS_PATH" "$@"
          fi
        done
      fi

      # Fallback: Exit successfully to prevent error messages
      # Chrome can handle status checks internally if the helper isn't found
      exit 0
    '')
  ];

  # Provide the custom Omarchy extension from the repo in the expected path
  # Chrome can use the same extension as Chromium
  home.file.".local/share/omarchy/default/chromium/extensions/copy-url".source =
    ../chromium/extensions/copy-url;
}
