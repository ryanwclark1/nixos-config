{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./build.nix
    ./deno.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./just.nix
    ./lazygit.nix
    ./nixdev.nix
    ./node.nix
    ./protobuf.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
  ];

}