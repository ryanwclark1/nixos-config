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
}
