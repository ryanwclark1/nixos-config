{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./build.nix
    ./deno.nix
    ./git.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./just.nix
    ./lazygit.nix
    ./nixdev.nix
    ./node.nix
    ./protobuf.nix
    ./python.nix
    ./rust.nix
    ./sql.nix
  ];

  options.development.enable = mkEnableOption "development packages";
  config = mkIf config.development.enable {

    build.enable = true;
    deno.enable = true;
    git.enable = true;
    gitui.enable = true;
    go.enable = true;
    grpc.enable = true;
    just.enable = true;
    lazygit.enable = true;
    nixdev.enable = true;
    node.enable = true;
    python.enable = true;
    protobuf.enable = true;
    rust.enable = true;
    sql.enable = true;
  };
}