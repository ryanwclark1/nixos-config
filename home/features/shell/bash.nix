{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      fastfetch() {
        if [ -x "$(command -v fastfetch)" ]; then
          fastfetch --print 2>/dev/null
        fi
      }
      #if [ -f $HOME/.bashrc-personal ]; then
      #source $HOME/.bashrc-personal
      #fi
    '';
    bashrcExtra = ''
      eval "$(zoxide init bash)"
      eval "$(atuin init bash)"
      set -o vi
    '';
    # enableVteIntegration = true;
    # historyControl = [ "ignoredups" ];
    # bashrcExtra = ''
    #   fastfetch() {
    #     if [ -x "$(command -v fastfetch)" ]; then
    #       fastfetch --print 2>/dev/null
    #     fi
    #   }
    # '';
  };


  programs.atuin.enableBashIntegration = mkIf config.programs.atuin.enable true;
  programs.fzf.enableBashIntegration = mkIf config.programs.fzf.enable true;
  programs.eza.enableBashIntegration = mkIf config.programs.eza.enable true;
  programs.nix-index.enableBashIntegration = mkIf config.programs.nix-index.enable true;
  programs.starship.enableBashIntegration = mkIf config.programs.starship.enable true;
  programs.zoxide.enableBashIntegration = mkIf config.programs.zoxide.enable true;
}
