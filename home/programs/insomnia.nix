# API Client for REST, GraphQL, GRPC and OpenAPI design tool for developers.
{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.insomnia.enable = mkEnableOption " insomnia options";

  config = mkIf config.insomnia.enable {
    home.packages = with pkgs; [
      insomnia
    ];
  };
}
