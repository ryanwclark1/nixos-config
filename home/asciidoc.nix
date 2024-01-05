{
  lib,
  config,
  pkgs,
  ...
}:

with lib; {
  options.asciidoc.enable = mkEnableOption "asciidoc settings";

  config = mkIf config.asciidoc.enable {
    home.packages = with pkgs; [
      asciidoc-full-with-plugins
      asciidoctor-with-extensions
    ];
  };
}