{
  pkgs,
  ...
}:

{
  home.file.".config/wallust/wallust.toml" = {
    source = ./wallust.toml;
  };

  home.file.".config/wallust/templates" = {
    source = ./templates;
    recursive = true;
  };

  home.packages = with pkgs; [
    pywal
    wallust
  ];
}