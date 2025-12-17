{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
  ];

  # Provide the custom extension from the repo in the expected path
  # Chrome can use the same extension as Chromium
  # home.file.".local/share/os/default/chromium/extensions/copy-url".source =
  #   ../chromium/extensions/copy-url;
}
