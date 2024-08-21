# Neomutt alternative
{
  pkgs,
  ...
}:

{
  programs.aerc = {
    enable = true;
    package = pkgs.aerc;
  };

}