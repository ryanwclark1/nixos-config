{
  pkgs,
  lib,
  ...
}:

{

  imports = [
    ./android.nix
    ./build.nix
    ./go.nix
    ./js.nix
    ./kotlin.nix
    ./lua.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
    ./swift.nix
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
    protolint
  ] ++ lib.optionals stdenv.isLinux [
    # System debugging (moved from desktop/common)
    d-spy # D-Bus debugger
  ];

}
