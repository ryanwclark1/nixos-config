{
  pkgs,
  ...
}:

{
  # Note home.shellAlias was not working when being called from other apps.
  home.packages = [
    (pkgs.google-chrome.override {
      commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland --force-dark-mode";
    })
    (pkgs.writeShellScriptBin "google-chrome" ''
       google-chrome-stable "$@"
    '')
  ];
}