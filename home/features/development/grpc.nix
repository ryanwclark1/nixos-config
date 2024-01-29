{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  home.packages = with pkgs; [
    grpcurl
    evans
    grpc
  ];
}
