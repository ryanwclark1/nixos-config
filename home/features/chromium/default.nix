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
      "--load-extension=${config.home.homeDirectory}/.local/share/os/default/chromium/extensions/copy-url"
    ];
  };

  # Provide the custom extension from the repo in the expected path
  home.file.".local/share/os/default/chromium/extensions/copy-url".source = ./extensions/copy-url;
}
