{
  lib,
  config,
  ...
}:
with lib; {
  options.doc.enable = mkEnableOption "documentation settings";

  config = mkIf config.doc.enable {
    programs = {
      info.enable = true;
      tealdeer.enable = true;
      # man.generateCaches = true;
    };
  };
}