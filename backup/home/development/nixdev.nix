{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib; {
  options.nixdev.enable = mkEnableOption "nix developement packages";
  config = mkIf config.nixdev.enable {
    home.packages = with pkgs; [
      alejandra
      niv
      nix-prefetch
      nix-prefetch-git
      nix-doc
      nix-update
      nix-template
      manix
      rnix-lsp
      deadnix
      patchelf
      nil
      nix-ld
      nix-top
      nix-tree
      nix-diff
      comma
      nixpkgs-lint
      nix-init
      statix
      # inputs.nix-alien.packages.${system}.nix-alien
      # nix-index-update
      inputs.aspen.packages.${system}.aspen
    ];

    programs.nix-index.enable = true;
  };
}