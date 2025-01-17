{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    google-chrome
  ];

  home.shellAliases = {
    google-chrome-stable = "google-chrome";
  };
}