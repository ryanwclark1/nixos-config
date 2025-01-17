{
  pkgs,
  ...
}:

{
  home.packages = [
    (pkgs.google-chrome-stable.override {
      commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland --force-dark-mode";
    })
  ];

  home.shellAliases = {
    google-chrome-stable = "google-chrome";
  };
}