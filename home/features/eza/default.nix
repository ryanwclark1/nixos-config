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
    icons = "auto";
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

  home.file.".config/eza/theme.yml" = {
    source = ./theme.yml;
    executable = false;
  };

  home.shellAliases = {
    ls = "eza -a --icons";
    l = "eza -lhg";
    la = "eza -a";
    ll = "eza -alhg";
    lt = "eza --tree";
    tree = "eza -la --git-ignore --icons --tree --hyperlink --level 4";
  };
}
