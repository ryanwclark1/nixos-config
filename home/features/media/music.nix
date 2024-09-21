{
  pkgs,
  ...
}:

{

  # programs.ncmpcpp = {
  #   package = pkgs.ncmpcpp.override { visualizerSupport = true; };
  #   enable = false;
  # };

  home.packages = with pkgs; [
    termusic
    spotify
  ];
}
