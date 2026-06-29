{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.features.productivity.logseq;
in
{
  options.features.productivity.logseq.enable = lib.mkEnableOption "Logseq" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      logseq
    ];
  };
}
