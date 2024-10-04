# A modern, maintained replacement for ls.
{
  lib,
  config,
  pkgs,
  ...
}:

{
  programs.eza = {
    enable = true;
    package = pkgs.eza;
    icons = true;
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--octal-permissions"
      "--hyperlink"
    ];
    enableBashIntegration = lib.mkIf config.programs.eza.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
    enableIonIntegration = lib.mkIf config.programs.ion.enable true;
  };

  home.shellAliases = {
    ls = "eza -a --icons";
    l = "eza -lhg";
    ll = "eza -alhg";
    lt = "eza --tree";
    # t = "eza -la --git-ignore --icons --tree --hyperlink --level 4";
    tree = "eza -la --git-ignore --icons --tree --hyperlink --level 4";
  };
}
