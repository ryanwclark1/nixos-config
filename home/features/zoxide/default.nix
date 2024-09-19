# zoxide is a smarter cd command, inspired by z and autojump.
{
  pkgs,
  ...
}:

{
  programs.zoxide = {
    enable = true;
    package = pkgs.zoxide;
    options = [
      "--cmd cd"
      "--hook pwd"
    ];
  };
}
