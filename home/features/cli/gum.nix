{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    gum # shell scripts
  ];
}