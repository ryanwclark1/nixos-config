{
  pkgs,
  ...
}:

{

  imports = [
    ./build.nix
    ./go.nix
    ./js.nix
    ./lua.nix
    # ./python.nix
    ./rust.nix
    ./sql.nix
    ./uv.nix
  ];


  home.packages = with pkgs; [
    pipx
    jsonnet-bundler
    jsonnet
    # GRPC
    grpcurl
    evans
    grpc
    # Protobuf
    protobuf
    protolint
    # System debugging (moved from desktop/common)
    d-spy # D-Bus debugger
  ] ++ (with pkgs.python313Packages; [
    pyyaml
  ]);

}
