{
  pkgs,
  ...
}:

{

  imports = [
    ./build.nix
    # ./go.nix
    ./js.nix
    ./lua.nix
    # ./python.nix
    ./rust.nix
    ./sql.nix
    ./uv.nix
  ];


  home.packages = with pkgs; [
    jsonnet-bundler
    jsonnet
    # GRPC
    grpcurl
    evans
    grpc
    # Protobuf
    protobuf
    go-protobuf
    protolint
    # System debugging (moved from desktop/common)
    d-spy # D-Bus debugger
  ];

}
