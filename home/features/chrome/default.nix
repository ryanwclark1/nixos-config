{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    google-chrome
    # Playwright browsers - provides bundled Chromium, Firefox, and WebKit
    # This ensures Playwright MCP can find browsers without path issues
    playwright.browsers
  ];

  # Provide the custom extension from the repo in the expected path
  # Chrome can use the same extension as Chromium
  # home.file.".local/share/os/default/chromium/extensions/copy-url".source =
  #   ../chromium/extensions/copy-url;

  # Environment variables for Playwright to find browsers in NixOS
  # Playwright will use its bundled browsers from playwright.browsers package
  home.sessionVariables = {
    # Point Playwright to use bundled browsers if playwright-mcp doesn't find system Chrome
    PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
  };
}
