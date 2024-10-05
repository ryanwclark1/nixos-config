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
    package = pkgs.bash;
    enableCompletion = true;
    enableVteIntegration = true;
    initExtra = ''
      if [ -x "$(command -v fastfetch)" ]; then
        fastfetch 2>/dev/null
      fi
    '';
    bashrcExtra = ''
      eval "$(zoxide init bash)"
      set -o vi
    '';
  };


  programs.nix-index.enableBashIntegration = lib.mkIf config.programs.nix-index.enable true;
  programs.kitty.shellIntegration.enableBashIntegration = lib.mkIf config.programs.kitty.enable true;
  programs.zellij.enableBashIntegration = lib.mkIf config.programs.zellij.enable false;

}
