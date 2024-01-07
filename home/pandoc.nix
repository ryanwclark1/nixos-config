#  a universal document converter
{
  lib,
  config,
  ...
}:

with lib; {
  options.pandoc.enable = mkEnableOption "pandoc settings";

  config = mkIf config.pandoc.enable {
    programs.pandoc = {
      enable = true;
      defaults = {
        metadata = {
          author = "RC";
        };
      };
    };
  };
}
