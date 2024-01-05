{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./bash.nix
    ./fish.nix
    ./nushell.nix
    ./tmux.nix
    ./zsh.nix
  ];

  options.shells.enable = mkEnableOption "shells packages";
  config = mkIf config.shells.enable {

    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    zsh.enable = true;
    tmux.enable = true;

  };
}