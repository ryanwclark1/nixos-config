{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    grpcurl
    evans
    grpc
  ];
}
