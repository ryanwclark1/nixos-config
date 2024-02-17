{ pkgs
, ...
}:

{

  imports = [
    ./build.nix
    ./devpod.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./js.nix
    ./lazygit.nix
    ./nixdev.nix
    ./protobuf.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
  ];

  home.packages = with pkgs; [
    so
  ];

}
