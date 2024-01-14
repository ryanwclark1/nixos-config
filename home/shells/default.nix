{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./alias.nix
    ./bash.nix
    ./fish.nix
    ./nushell.nix
    ./tmux.nix
    ./zellij.nix
    ./zsh.nix
  ];

  options.shells.enable = mkEnableOption "shells packages";
  config = mkIf config.shells.enable {

    alias.enable = true;
    bash.enable = true;
    fish.enable = true;
    nushell.enable = true;
    tmux.enable = true;
    zellij.enable = true;
    zsh.enable = true;

  };
}