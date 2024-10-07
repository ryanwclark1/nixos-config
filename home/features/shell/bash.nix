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
    package = pkgs.bashInteractive;
    enableCompletion = true;
    enableVteIntegration = true;
    initExtra = ''
      if [ -x "$(command -v fastfetch)" ]; then
        fastfetch 2>/dev/null
      fi
    '';
    # bashrcExtra = ''
    #   eval "$(zoxide init bash)"
    #   set -o vi
    # '';
  };



}
