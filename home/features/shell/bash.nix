{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    blesh
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    initExtra = ''
      if [ -x "$(command -v fastfetch)" ]; then
        fastfetch --config all 2>/dev/null
      fi
    '';
    bashrcExtra = ''
      eval "$(zoxide init bash)"
      eval "$(atuin init bash)"
      set -o vi
    '';
  };

  programs.atuin.enableBashIntegration = lib.mkIf config.programs.atuin.enable true;
  programs.fzf.enableBashIntegration = lib.mkIf config.programs.fzf.enable true;
  programs.eza.enableBashIntegration = lib.mkIf config.programs.eza.enable true;
  programs.nix-index.enableBashIntegration = lib.mkIf config.programs.nix-index.enable true;
  programs.kitty.shellIntegration.enableBashIntegration = lib.mkIf config.programs.kitty.enable true;
  programs.starship.enableBashIntegration = lib.mkIf config.programs.starship.enable true;
  programs.yazi.enableBashIntegration = lib.mkIf config.programs.yazi.enable true;
  programs.zellij.enableBashIntegration = lib.mkIf config.programs.zellij.enable false;
  programs.zoxide.enableBashIntegration = lib.mkIf config.programs.zoxide.enable true;
}
