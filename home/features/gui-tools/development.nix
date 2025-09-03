{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    dbeaver-bin # Universal Database Tool
    # devpod-desktop # Codespaces but open-source, client-only and unopinionated: Works with any IDE - BROKEN: Tauri version mismatch
    insomnia # API Client for REST, GraphQL, GRPC and OpenAPI design tool for developers.
    postman # API Development Environment
    sqlitebrowser # Visual tool to create, design, and edit database files compatible with SQLite
  ];
}
