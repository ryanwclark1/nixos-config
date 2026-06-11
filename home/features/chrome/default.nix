{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    google-chrome
  ];

  home.sessionVariables = {
    # Playwright's Chrome autodiscovery is brittle on NixOS because the
    # browser lives in the Nix store rather than a conventional Linux path.
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };
}
