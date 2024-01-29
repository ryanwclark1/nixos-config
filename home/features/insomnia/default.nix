# API Client for REST, GraphQL, GRPC and OpenAPI design tool for developers.
{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  home.packages = with pkgs; [
    insomnia
  ];
}
