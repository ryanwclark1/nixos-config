{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    comma
    deadnix
    niv
    nix-diff
    nvd
    nix-tree # Interactively browse dependency graphs of Nix derivations
    nurl # Generate Nix fetcher calls from repository URLs
    patchelf
    sops
    nix-prefetch-git # nix development
  ];
}
