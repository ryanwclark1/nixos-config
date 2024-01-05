{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./helix.nix
    ./insomnia.nix
    ./neovim.nix
    ./vscode.nix

  ];

  options.editors.enable = mkEnableOption "editorss packages";
  config = mkIf config.editors.enable {
    helix.enable = true;
    insomnia.enable = true;
    neovim.enable = true;
    vscode.enable = true;
  };
}