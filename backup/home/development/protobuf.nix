{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.protobuf.enable = mkEnableOption "protobuf settings";

  config = mkIf config.protobuf.enable {
    home.packages = with pkgs; [
      protobuf
      protoc-gen-rust
      go-protobuf
      buf-language-server
      buf
      protolint
    ];
  };
}
