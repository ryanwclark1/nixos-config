{
  pkgs,
  ...
}:

{
  home.packages = [
    (pkgs.google-chrome.override {
      commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland --force-dark-mode";
    })
  ];

  home.shellAliases = {
    google-chrome-stable = "google-chrome";
  };
}