# API Client for REST, GraphQL, GRPC and OpenAPI design tool for developers.
{ pkgs
, ...
}:

{
  home.packages = with pkgs; [
    insomnia
  ];
}
