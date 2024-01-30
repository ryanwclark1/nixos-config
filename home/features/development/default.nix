{
  pkgs,
  ...
}:

{

  imports = [
    ./build.nix
    ./deno.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./lazygit.nix
    ./nixdev.nix
    ./node.nix
    ./protobuf.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
  ];

  home.packages = with pkgs; [
    so
  ];

}