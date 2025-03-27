# This file defines overlays
{
  inputs,
  ...
}:

{

  # https://nixos.wiki/wiki/Overlays
  windsurf = import ./windsurf.nix { inherit inputs; };
  # Export individual overlays
  # uv = import ./uv.nix { inherit inputs; };
  # vscode = import ./vscode.nix { inherit inputs; };
  # newpackage = import ./newpackage.nix { inherit inputs; };
  # unstable-packages = import ./unstable-packages.nix { inherit inputs; };

  # Combined overlays
  # default = final: prev:
    # (import ./uv.nix { inherit inputs; }) final prev //
  #   (import ./vscode.nix { inherit inputs; }) final prev //
  #   (import ./newpackage.nix { inherit inputs; }) final prev //
    # (import ./unstable-packages.nix { inherit inputs; }) final prev;
}

