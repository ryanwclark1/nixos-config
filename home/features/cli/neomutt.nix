{
  pkgs,
  ...
}:

{
  programs.neomutt = {
    enable = true;
    package = pkgs.neomutt;
    editor = "$EDITOR";
  };
}