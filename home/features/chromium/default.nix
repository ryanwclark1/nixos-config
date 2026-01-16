{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--ozone-platform-hint=wayland"
      "--enable-features=TouchpadOverscrollHistoryNavigation"
      # Chromium crash workaround for Wayland color management on Hyprland
      "--disable-features=WaylandWpColorManagerV1"
      "--load-extension=${config.home.homeDirectory}/.local/share/os/default/chromium/extensions/copy-url"
    ];
    # dictionaries = [ pkgs.hunspellDicts.en_US ];
    extensions = [ ];
    nativeMessagingHosts = [ ];
  };

  # Provide the custom extension from the repo in the expected path
  home.file.".local/share/os/default/chromium/extensions/copy-url".source = ./extensions/copy-url;

  # Environment variables for Playwright to find browsers in NixOS
  # This ensures Playwright MCP can use bundled browsers (Chromium, Firefox, WebKit)
  # Note: playwright.browsers package is provided by home/features/ai/default.nix
  home.sessionVariables = {
    # Point Playwright to use bundled browsers for reliable operation in NixOS
    PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
  };
}
