# A lightweight and flexible command-line JSON processor
{
  pkgs,
  ...
}:

{
  programs.jq = {
    enable = true;
    package = pkgs.jq;
  };
  home.packages = with pkgs; [
    jnv  # https://github.com/ynqa/jnv
  ];
}
