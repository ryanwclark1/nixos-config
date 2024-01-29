{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  home.packages = with pkgs; [
    protobuf
    protoc-gen-rust
    go-protobuf
    buf-language-server
    buf
    protolint
  ];
}
