{
  pkgs,
  ...
}:

{
  programs.ncmpcpp = {
    package = pkgs.ncmpcpp;
    enable = true;
  };
}
