# A lightweight and flexible command-line JSON processor

{
  config,
  lib,
  ...
}:
with lib; {
  options.jq.enable = mkEnableOption "jq settings";

  config = mkIf config.jq.enable {
    programs.jq = {
      enable = true;
    };
  };
}