{
  pkgs,
  ...
}:

let
  scriptFile = ./nix-prefetch-git; # Path to your shell script file
  myBinary = pkgs.writeShellScriptBin "nix-prefetch-git" (pkgs.readFile scriptFile);
in

{
  # Exporting the binary
  myBinary = myBinary;
}