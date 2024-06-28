# A modern, maintained replacement for ls.
{
  ...
}:

{
  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  home.shellAliases = {
    ls = "eza";
    l = "eza -lhg";
    ll = "eza -alhg";
    lt = "eza --tree";
  };
}