{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    # Playwright CLI for global usage
    # This provides the 'playwright' command
    playwright
    # Playwright browsers - includes all browser components:
    # - Chromium (full browser)
    # - Chromium Headless Shell (lightweight headless version)
    # - Firefox
    # - WebKit
    # - FFmpeg (for video/audio recording and processing)
    # Chromium is the default, but all others are available when needed
    # Use playwright.browsers-chromium if you only want Chromium
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
