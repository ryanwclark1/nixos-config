{
  configs,
  pkgs,
  ...
}:

let
  scriptFile = ./nix-prefetch-git; # Path to your shell script file
  myBinary = pkgs.writeShellScriptBin "nix-prefetch-git" (builtins.readFile scriptFile);
in

{
  # Exporting the binary
#  home.packages = [
#     myBinary
#   ];
}