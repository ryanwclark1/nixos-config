# A modern, maintained replacement for ls.
{
  lib,
  config,
  pkgs,
  ...
}:

{
  imports = [ ./theme.yml.nix ];

  programs.eza = {
    enable = true;
    package = pkgs.eza;
    icons = "auto";
    colors = "always";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--octal-permissions"
      "--hyperlink"
    ];
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
    enableIonIntegration = lib.mkIf config.programs.ion.enable true;
  };

  home.shellAliases = {
    ls = "eza --all --icons";
    l = "eza --all --long --header --group";
    lt = "eza --long --all --git-ignore --icons --tree --hyperlink";
  };
}
