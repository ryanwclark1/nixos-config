{
  pkgs,
  ...
}:

{

  imports = [
    ./build.nix
    # ./devpod.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./js.nix
    ./lazygit.nix
    ./lua.nix
    ./postman.nix
    ./protobuf.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
  ];

  home.packages = with pkgs; [
    so
    tokei # code statistics
  ];

}
