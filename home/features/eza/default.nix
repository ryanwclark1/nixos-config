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
      "--octal-permissions"
      "--hyperlink"
    ];
  };

  home.shellAliases = {
    ls = "eza -a --icons";
    l = "eza -lhg";
    ll = "eza -alhg";
    lt = "eza --tree";
    t = "eza -la --git-ignore --icons --tree --hyperlink --level 4";
    tree = "eza -la --git-ignore --icons --tree --hyperlink --level 4";
  };
}
