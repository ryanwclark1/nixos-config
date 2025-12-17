{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
  ];

  # Provide the custom Omarchy extension from the repo in the expected path
  # Chrome can use the same extension as Chromium
  # home.file.".local/share/omarchy/default/chromium/extensions/copy-url".source =
  #   ../chromium/extensions/copy-url;
}
