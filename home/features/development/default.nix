{
  pkgs,
  ...
}:

{

  imports = [
    ./build.nix
    # ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./js.nix
    ./lua.nix
    ./protobuf.nix
    # ./python.nix
    ./rust.nix
    ./sql.nix
  ];

  home.packages = with pkgs; [
    so
    tokei # code statistics
    cachix
    nix-prefetch-git # nix development
    nix-prefetch-url # nix Development
  ];

}
