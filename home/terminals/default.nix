{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./alacritty.nix
    ./kitty.nix

  ];

  options.terminals.enable = mkEnableOption "terminals packages";
  config = mkIf config.terminals.enable {
    alacritty.enable = true;
    kitty.enable = true;
  };
}