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
  ];

  # Provide the custom Omarchy extension from the repo in the expected path
  # Chrome can use the same extension as Chromium
  home.file.".local/share/omarchy/default/chromium/extensions/copy-url".source =
    ../chromium/extensions/copy-url;
}
