{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.grpc.enable = mkEnableOption "grpc settings";

  config = mkIf config.grpc.enable {
    home.packages = with pkgs; [grpcurl evans grpc];
  };
}
