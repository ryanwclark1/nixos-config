# This file defines overlays
{
  inputs,
  outputs,
  ...
}:

{
  # https://nixos.wiki/wiki/Overlays

  # Export individual overlays
  # uv = import ./uv.nix { inherit inputs; };
  # vscode = import ./vscode.nix { inherit inputs; };
  # newpackage = import ./newpackage.nix { inherit inputs; };
  # unstable-packages = import ./unstable-packages.nix { inherit inputs; };

  # Combined overlays
  default = final: prev:
    # (import ./uv.nix { inherit inputs; }) final prev //
  #   (import ./vscode.nix { inherit inputs; }) final prev //
  #   (import ./newpackage.nix { inherit inputs; }) final prev //
    (import ./unstable-packages.nix { inherit inputs; }) final prev;
}

